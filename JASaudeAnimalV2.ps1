# ============================================================
#  JA Saude Animal - Ferramenta de TI
#  by JA Saude Animal
#  v1.0 - Instalacao de Programas + Ferramentas de Sistema
# ============================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Cores ---
$corFundo       = [System.Drawing.Color]::FromArgb(245, 248, 245)
$corPainel      = [System.Drawing.Color]::FromArgb(255, 255, 255)
$corBorda       = [System.Drawing.Color]::FromArgb(200, 220, 200)
$corDestaque    = [System.Drawing.ColorTranslator]::FromHtml("#19984B")
$corAmarelo     = [System.Drawing.ColorTranslator]::FromHtml("#EECD65")
$corVerde       = [System.Drawing.ColorTranslator]::FromHtml("#19984B")
$corVerdeClaro  = [System.Drawing.Color]::FromArgb(220, 240, 220)
$corAmareloClr  = [System.Drawing.Color]::FromArgb(255, 243, 205)
$corVermelho    = [System.Drawing.Color]::FromArgb(200, 50, 50)
$corTexto       = [System.Drawing.Color]::FromArgb(30, 50, 30)
$corTextoClaro  = [System.Drawing.Color]::FromArgb(255, 255, 255)
$corTextoEscuro = [System.Drawing.Color]::FromArgb(100, 120, 100)
$corTabInativa  = [System.Drawing.Color]::FromArgb(235, 245, 235)
$corTabHover    = [System.Drawing.Color]::FromArgb(210, 235, 210)
$corSidebar     = [System.Drawing.Color]::FromArgb(30, 80, 50)
$corSidebarText = [System.Drawing.Color]::FromArgb(220, 245, 220)
$corSidebarHov  = [System.Drawing.Color]::FromArgb(46, 110, 70)
$corSidebarSel  = [System.Drawing.ColorTranslator]::FromHtml("#19984B")

# --- Funcoes Core ---
function Escrever-Log {
    param([string]$Msg, [string]$Tipo = "INFO")
    $ts    = Get-Date -Format "HH:mm:ss"
    $linha = "[$ts][$Tipo] $Msg"
    Write-Host $linha
    if ($script:txtLog -and !$script:txtLog.IsDisposed) {
        $script:txtLog.Invoke([System.Action]{
            $script:txtLog.AppendText("$linha`r`n")
            $script:txtLog.ScrollToCaret()
        }) | Out-Null
    }
}

function RegSet {
    param([string]$path, [string]$name, $value, [string]$type = "DWord")
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -ErrorAction SilentlyContinue
}

function Svc-Disable {
    param([string]$Nome)
    try {
        Stop-Service -Name $Nome -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $Nome -StartupType Disabled -ErrorAction SilentlyContinue
        Escrever-Log "Servico '$Nome' desativado!" "OK"
    } catch { Escrever-Log "Aviso ($Nome): $_" "AVISO" }
}

function Rodar-Async {
    param(
        [ScriptBlock]$Bloco,
        [hashtable]$Vars          = @{},
        [ScriptBlock]$AoFinalizar = $null
    )
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions  = "ReuseThread"
    $rs.Open()
    foreach ($k in $Vars.Keys) { $rs.SessionStateProxy.SetVariable($k, $Vars[$k]) }
    $fnLog    = ${function:Escrever-Log}.ToString()
    $fnRegSet = ${function:RegSet}.ToString()
    $fnSvcDis = ${function:Svc-Disable}.ToString()
    $rs.SessionStateProxy.SetVariable("fnLog",    $fnLog)
    $rs.SessionStateProxy.SetVariable("fnRegSet", $fnRegSet)
    $rs.SessionStateProxy.SetVariable("fnSvcDis", $fnSvcDis)
    $rs.SessionStateProxy.SetVariable("txtLogRef",  $script:txtLog)
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript({
        Invoke-Expression "function Escrever-Log { $fnLog }"
        Invoke-Expression "function RegSet { $fnRegSet }"
        Invoke-Expression "function Svc-Disable { $fnSvcDis }"
        $script:txtLog = $txtLogRef
    }) | Out-Null
    $ps.AddScript($Bloco) | Out-Null
    $handle = $ps.BeginInvoke()

    $script:_asyncIdx = if ($script:_asyncIdx -is [int]) { $script:_asyncIdx + 1 } else { 0 }
    $myIdx = $script:_asyncIdx
    $script:_asyncCallbacks = if ($script:_asyncCallbacks -is [hashtable]) { $script:_asyncCallbacks } else { @{} }
    $script:_asyncCallbacks[$myIdx] = $AoFinalizar

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 500
    $timer.add_Tick({
        if (-not $handle.IsCompleted) { return }
        $timer.Stop()
        $timer.Dispose()
        try { $ps.EndInvoke($handle) } catch {}
        try { $ps.Dispose() }   catch {}
        try { $rs.Close() }     catch {}
        try { $rs.Dispose() }   catch {}
        $cb = $script:_asyncCallbacks[$myIdx]
        $script:_asyncCallbacks.Remove($myIdx)
        if ($cb) {
            try { & $cb } catch { Write-Host "AoFinalizar erro: $_" }
        }
    })
    $timer.Start()
}

function Criar-Icone {
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(46, 139, 87))
    $g.FillEllipse($brush, 0, 0, 15, 15)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 2)
    $g.DrawLine($pen, 3, 8, 6, 12)
    $g.DrawLine($pen, 6, 12, 13, 4)
    $g.Dispose(); $pen.Dispose(); $brush.Dispose()
    $icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
    $bmp.Dispose()
    return $icon
}

# =================================================================
#  DEFINICAO DOS PROGRAMAS
# =================================================================

# Pacote "Todos os apps basicos" - instalados via winget/chocolatey
$appsBasicos = @(
    # Navegadores
    @{ Nome="Firefox";                  Winget="Mozilla.Firefox" }
    @{ Nome="Google Chrome";            Winget="Google.Chrome" }
    @{ Nome="Microsoft Edge";           Winget="Microsoft.Edge" }
    # Utilitarios
    @{ Nome="7-Zip";                    Winget="7zip.7zip" }
    # VC Redist - todos
    @{ Nome="VC Redist x86 2005";       Winget="Microsoft.VCRedist.2005.x86" }
    @{ Nome="VC Redist x64 2005";       Winget="Microsoft.VCRedist.2005.x64" }
    @{ Nome="VC Redist x86 2008";       Winget="Microsoft.VCRedist.2008.x86" }
    @{ Nome="VC Redist x64 2008";       Winget="Microsoft.VCRedist.2008.x64" }
    @{ Nome="VC Redist x86 2010";       Winget="Microsoft.VCRedist.2010.x86" }
    @{ Nome="VC Redist x64 2010";       Winget="Microsoft.VCRedist.2010.x64" }
    @{ Nome="VC Redist x86 2012";       Winget="Microsoft.VCRedist.2012.x86" }
    @{ Nome="VC Redist x64 2012";       Winget="Microsoft.VCRedist.2012.x64" }
    @{ Nome="VC Redist x86 2013";       Winget="Microsoft.VCRedist.2013.x86" }
    @{ Nome="VC Redist x64 2013";       Winget="Microsoft.VCRedist.2013.x64" }
    @{ Nome="VC Redist x86 2015+";      Winget="Microsoft.VCRedist.2015+.x86" }
    @{ Nome="VC Redist x64 2015+";      Winget="Microsoft.VCRedist.2015+.x64" }
    # .NET Runtimes
    @{ Nome=".NET Desktop Runtime 8 x86"; Winget="Microsoft.DotNet.DesktopRuntime.8.x86" }
    @{ Nome=".NET Desktop Runtime 8 x64"; Winget="Microsoft.DotNet.DesktopRuntime.8.x64" }
    @{ Nome=".NET Desktop Runtime 9 x64"; Winget="Microsoft.DotNet.DesktopRuntime.9" }
    @{ Nome=".NET Desktop Runtime 10 x64";Winget="Microsoft.DotNet.DesktopRuntime.10" }
    # Comunicacao
    @{ Nome="OneDrive";                 Winget="Microsoft.OneDrive" }
    @{ Nome="Zoom";                     Winget="Zoom.Zoom" }
    @{ Nome="Microsoft Teams";          Winget="Microsoft.Teams" }
    # Suporte remoto
    @{ Nome="TeamViewer 15";            Winget="TeamViewer.TeamViewer" }
)

# Apps individuais (checkboxes separados)
$appsIndividuais = @(
    @{ Nome="Adobe Acrobat Reader 64-bit"; Winget="Adobe.Acrobat.Reader.64-bit";  Desc="Leitor PDF oficial Adobe (64-bit)" }
    @{ Nome="PDF24 Creator";               Winget="geeksoftwareGmbH.PDF24Creator";  Desc="Criador e editor de PDF gratuito" }
    @{ Nome="Office 365 Setup";            Winget="Microsoft.Office";              Desc="Microsoft Office 365 (instalador)" }
    @{ Nome="CutePDF Writer";              Winget="AcroSoftware.CutePDFWriter";    Desc="Impressora virtual para criar PDFs" }
    @{ Nome="OBS Studio";                  Winget="OBSProject.OBSStudio";           Desc="Gravacao e streaming de video" }
    @{ Nome="Java 8 (JRE)";               Winget="Oracle.JavaRuntimeEnvironment";  Desc="Java Runtime Environment 8" }
    @{ Nome="VS Code";                     Winget="Microsoft.VisualStudioCode";     Desc="Editor de codigo Microsoft" }
    @{ Nome="VLC";                         Winget="VideoLAN.VLC";                   Desc="Player de midia universal" }
    @{ Nome="Google Earth Pro";            Winget="Google.EarthPro";          Desc="Explorador de mapas 3D" }
)

# =================================================================
#  JANELA PRINCIPAL
# =================================================================
$script:form = New-Object System.Windows.Forms.Form
$script:form.Text          = "JA Saude Animal  |  Ferramenta de TI"
$script:form.Size          = New-Object System.Drawing.Size(1180, 760)
$script:form.StartPosition = "CenterScreen"
$script:form.BackColor     = $corFundo
$script:form.ForeColor     = $corTexto
$script:form.Font          = New-Object System.Drawing.Font("Segoe UI", 9)
$script:form.MinimumSize   = New-Object System.Drawing.Size(960, 640)
$script:form.Icon          = Criar-Icone

# --- Barra de acento topo ---
$pnlAccent = New-Object System.Windows.Forms.Panel
$pnlAccent.Dock = "Top"; $pnlAccent.Height = 4; $pnlAccent.BackColor = $corDestaque
$script:form.Controls.Add($pnlAccent)

# --- Header ---
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock = "Top"; $pnlHeader.Height = 58; $pnlHeader.BackColor = $corPainel

$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text      = "JA Saude Animal"
$lblTitulo.Font      = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblTitulo.ForeColor = $corDestaque
$lblTitulo.Location  = New-Object System.Drawing.Point(18, 8)
$lblTitulo.AutoSize  = $true

$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text      = "v1.0"
$lblVersion.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblVersion.ForeColor = $corTextoEscuro
$lblVersion.Location  = New-Object System.Drawing.Point(230, 12)
$lblVersion.AutoSize  = $true

$sepHeaderV = New-Object System.Windows.Forms.Panel
$sepHeaderV.Location  = New-Object System.Drawing.Point(268, 10)
$sepHeaderV.Size      = New-Object System.Drawing.Size(1, 36)
$sepHeaderV.BackColor = $corBorda

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text      = "Ferramenta de Instalacao e Configuracao  |  TI JA Saude Animal"
$lblSub.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
$lblSub.ForeColor = $corTextoEscuro
$lblSub.Location  = New-Object System.Drawing.Point(278, 20)
$lblSub.AutoSize  = $true

$pnlHeader.Controls.AddRange(@($lblTitulo, $lblVersion, $sepHeaderV, $lblSub))
$script:form.Controls.Add($pnlHeader)

# --- Container principal ---
$pnlMain = New-Object System.Windows.Forms.Panel
$pnlMain.Location  = New-Object System.Drawing.Point(0, 66)
$pnlMain.Size      = New-Object System.Drawing.Size(1180, 660)
$pnlMain.Anchor    = "Top,Left,Bottom,Right"
$pnlMain.BackColor = $corFundo
$script:form.Controls.Add($pnlMain)

# --- Sidebar ---
$pnlSidebar = New-Object System.Windows.Forms.Panel
$pnlSidebar.Location  = New-Object System.Drawing.Point(0, 0)
$pnlSidebar.Size      = New-Object System.Drawing.Size(190, 660)
$pnlSidebar.Anchor    = "Top,Left,Bottom"
$pnlSidebar.BackColor = $corSidebar
$pnlMain.Controls.Add($pnlSidebar)

$sepSide = New-Object System.Windows.Forms.Panel
$sepSide.Location = New-Object System.Drawing.Point(190, 0)
$sepSide.Size     = New-Object System.Drawing.Size(1, 660)
$sepSide.Anchor   = "Top,Left,Bottom"
$sepSide.BackColor= $corBorda
$pnlMain.Controls.Add($sepSide)

# --- Area de conteudo ---
$pnlContent = New-Object System.Windows.Forms.Panel
$pnlContent.Location  = New-Object System.Drawing.Point(191, 0)
$pnlContent.Size      = New-Object System.Drawing.Size(749, 660)
$pnlContent.Anchor    = "Top,Left,Bottom,Right"
$pnlContent.BackColor = $corFundo
$pnlMain.Controls.Add($pnlContent)

# --- Log panel ---
$sepLog = New-Object System.Windows.Forms.Panel
$sepLog.Location = New-Object System.Drawing.Point(940, 0)
$sepLog.Size     = New-Object System.Drawing.Size(1, 660)
$sepLog.Anchor   = "Top,Right,Bottom"
$sepLog.BackColor= $corBorda
$pnlMain.Controls.Add($sepLog)

$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.Location  = New-Object System.Drawing.Point(941, 0)
$pnlLog.Size      = New-Object System.Drawing.Size(239, 660)
$pnlLog.Anchor    = "Top,Right,Bottom"
$pnlLog.BackColor = $corFundo
$pnlMain.Controls.Add($pnlLog)

# =================================================================
#  TABS
# =================================================================
$tabDefs = @(
    @{ Label="Instalar Programas"; Icon="[+]" }
    @{ Label="Sistema";            Icon="[S]" }
)

$tabPanels  = [System.Collections.ArrayList]@()
$tabButtons = [System.Collections.ArrayList]@()

function Criar-TabPanel {
    $p = New-Object System.Windows.Forms.Panel
    $p.Dock = "Fill"; $p.BackColor = $corFundo; $p.Visible = $false
    $pnlContent.Controls.Add($p)
    return $p
}

function Selecionar-Tab {
    param([int]$idx)
    $script:tabAtual = $idx
    for ($i = 0; $i -lt $tabPanels.Count; $i++) { $tabPanels[$i].Visible = ($i -eq $idx) }
    for ($i = 0; $i -lt $tabButtons.Count; $i++) {
        if ($i -eq $idx) {
            $tabButtons[$i].BackColor = $corSidebarSel
            $tabButtons[$i].ForeColor = $corTextoClaro
        } else {
            $tabButtons[$i].BackColor = $corSidebar
            $tabButtons[$i].ForeColor = $corSidebarText
        }
    }
}

$yBtn = 16
foreach ($def in $tabDefs) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = "  $($def.Icon)  $($def.Label)"
    $btn.Location  = New-Object System.Drawing.Point(6, $yBtn)
    $btn.Size      = New-Object System.Drawing.Size(174, 44)
    $btn.BackColor = $corSidebar
    $btn.ForeColor = $corSidebarText
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.FlatAppearance.MouseOverBackColor = $corSidebarHov
    $btn.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.TextAlign = "MiddleLeft"
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btn.Tag       = $tabButtons.Count
    $pnl = Criar-TabPanel
    $tabPanels.Add($pnl)  | Out-Null
    $tabButtons.Add($btn) | Out-Null
    $btn.add_Click({ Selecionar-Tab -idx $this.Tag })
    $pnlSidebar.Controls.Add($btn)
    $yBtn += 50
}

# Linha separadora na sidebar
$sepSideLine = New-Object System.Windows.Forms.Panel
$sepSideLine.Location  = New-Object System.Drawing.Point(10, ($yBtn - 4))
$sepSideLine.Size      = New-Object System.Drawing.Size(166, 1)
$sepSideLine.BackColor = $corSidebarHov
$pnlSidebar.Controls.Add($sepSideLine)

# Credito
$lblCredit = New-Object System.Windows.Forms.Label
$lblCredit.Text      = "JA Saude Animal - TI"
$lblCredit.ForeColor = $corSidebarHov
$lblCredit.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
$lblCredit.Location  = New-Object System.Drawing.Point(8, 620)
$lblCredit.AutoSize  = $true
$pnlSidebar.Controls.Add($lblCredit)

# =================================================================
#  ABA 0 - INSTALAR PROGRAMAS
# =================================================================
$pInst = $tabPanels[0]

$pnlInstScroll = New-Object System.Windows.Forms.Panel
$pnlInstScroll.Dock       = "Fill"
$pnlInstScroll.BackColor  = $corFundo
$pnlInstScroll.AutoScroll = $true

# --- CONTADOR ---
$script:lblContadorInst = New-Object System.Windows.Forms.Label
$script:lblContadorInst.Text      = "0 item(ns) selecionado(s)"
$script:lblContadorInst.ForeColor = $corTextoEscuro
$script:lblContadorInst.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

function Atualizar-ContadorInst {
    $total = 0
    if ($script:chkBasicos -and $script:chkBasicos.Checked) { $total++ }
    foreach ($chk in $script:chksIndividuais) {
        if ($chk.Checked) { $total++ }
    }
    $script:lblContadorInst.Text      = "$total item(ns) selecionado(s)"
    $script:lblContadorInst.ForeColor = if ($total -gt 0) { $corDestaque } else { $corTextoEscuro }
}

# -------------------------------------------------------
#  BLOCO: TODOS OS APPS BASICOS
# -------------------------------------------------------
$yScroll = 14

$pnlBlocoBasico = New-Object System.Windows.Forms.Panel
$pnlBlocoBasico.Location  = New-Object System.Drawing.Point(14, $yScroll)
$pnlBlocoBasico.Size      = New-Object System.Drawing.Size(700, 0)
$pnlBlocoBasico.BackColor = $corPainel

# Barra verde topo
$barBasico = New-Object System.Windows.Forms.Panel
$barBasico.Location  = New-Object System.Drawing.Point(0, 0)
$barBasico.Size      = New-Object System.Drawing.Size(700, 4)
$barBasico.BackColor = $corDestaque
$pnlBlocoBasico.Controls.Add($barBasico)

# Header
$lblBasicoTit = New-Object System.Windows.Forms.Label
$lblBasicoTit.Text      = "Pacote Completo - Todos os Apps Basicos"
$lblBasicoTit.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblBasicoTit.ForeColor = $corDestaque
$lblBasicoTit.Location  = New-Object System.Drawing.Point(14, 14)
$lblBasicoTit.AutoSize  = $true
$pnlBlocoBasico.Controls.Add($lblBasicoTit)

# Descricao do que esta incluso (texto simples, sem lista)
$descBasico = "Inclui: Firefox, Chrome, Edge, 7-Zip, VC Redist (x86/x64: 2005, 2008, 2010, 2012, 2013, 2015+), " +
              ".NET Desktop Runtime (8, 9, 10 - x86 e x64), .NET Framework 4.8.1, " +
              "OneDrive, Zoom, Microsoft Teams, TeamViewer 15."

$lblBasicoDesc = New-Object System.Windows.Forms.Label
$lblBasicoDesc.Text      = $descBasico
$lblBasicoDesc.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblBasicoDesc.ForeColor = $corTextoEscuro
$lblBasicoDesc.Location  = New-Object System.Drawing.Point(44, 42)
$lblBasicoDesc.Size      = New-Object System.Drawing.Size(640, 40)
$pnlBlocoBasico.Controls.Add($lblBasicoDesc)

# Checkbox principal
$script:chkBasicos = New-Object System.Windows.Forms.CheckBox
$script:chkBasicos.Text      = "Instalar todos os apps basicos acima"
$script:chkBasicos.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:chkBasicos.ForeColor = $corDestaque
$script:chkBasicos.BackColor = $corPainel
$script:chkBasicos.Location  = New-Object System.Drawing.Point(14, 88)
$script:chkBasicos.Size      = New-Object System.Drawing.Size(660, 26)
$script:chkBasicos.Cursor    = [System.Windows.Forms.Cursors]::Hand

# Visual Moderno (Flat)
$script:chkBasicos.FlatStyle = "Flat"
$script:chkBasicos.FlatAppearance.BorderSize = 0
$script:chkBasicos.FlatAppearance.CheckedBackColor = $corVerdeClaro

$script:chkBasicos.add_CheckedChanged({ Atualizar-ContadorInst })
$pnlBlocoBasico.Controls.Add($script:chkBasicos)

$alturaBloco1 = 4 + 14 + 24 + 44 + 28 + 14
$pnlBlocoBasico.Height = $alturaBloco1
$pnlInstScroll.Controls.Add($pnlBlocoBasico)

# -------------------------------------------------------
#  BLOCO: APPS INDIVIDUAIS
# -------------------------------------------------------
$yScroll2 = $yScroll + $alturaBloco1 + 14

$pnlBlocoIndiv = New-Object System.Windows.Forms.Panel
$pnlBlocoIndiv.Location  = New-Object System.Drawing.Point(14, $yScroll2)
$pnlBlocoIndiv.BackColor = $corPainel

$barIndiv = New-Object System.Windows.Forms.Panel
$barIndiv.Location  = New-Object System.Drawing.Point(0, 0)
$barIndiv.Size      = New-Object System.Drawing.Size(700, 4)
$barIndiv.BackColor = $corAmarelo
$pnlBlocoIndiv.Controls.Add($barIndiv)

$lblIndivTit = New-Object System.Windows.Forms.Label
$lblIndivTit.Text      = "Aplicativos Adicionais"
$lblIndivTit.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblIndivTit.ForeColor = $corAmarelo
$lblIndivTit.Location  = New-Object System.Drawing.Point(14, 14)
$lblIndivTit.AutoSize  = $true
$pnlBlocoIndiv.Controls.Add($lblIndivTit)

# Checkboxes individuais
$script:chksIndividuais = @()
$yChk = 46

foreach ($app in $appsIndividuais) {
    # Painel de cada app (checkbox + descricao)
    $pnlApp = New-Object System.Windows.Forms.Panel
    $pnlApp.Location  = New-Object System.Drawing.Point(8, $yChk)
    $pnlApp.Size      = New-Object System.Drawing.Size(680, 34)
    $pnlApp.BackColor = $corPainel

    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text      = $app.Nome
    $chk.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $chk.ForeColor = $corTexto
    $chk.BackColor = $corPainel
    $chk.Location  = New-Object System.Drawing.Point(4, 6)
    $chk.Size      = New-Object System.Drawing.Size(280, 22)
    $chk.Cursor    = [System.Windows.Forms.Cursors]::Hand

    # Visual Moderno (Flat)
    $chk.FlatStyle = "Flat"
    $chk.FlatAppearance.BorderSize = 0
    $chk.FlatAppearance.CheckedBackColor = $corVerdeClaro

    $chk.add_CheckedChanged({ Atualizar-ContadorInst })
    $pnlApp.Controls.Add($chk)

    $lblDesc = New-Object System.Windows.Forms.Label
    $lblDesc.Text      = $app.Desc
    $lblDesc.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
    $lblDesc.ForeColor = $corTextoEscuro
    $lblDesc.Location  = New-Object System.Drawing.Point(290, 9)
    $lblDesc.Size      = New-Object System.Drawing.Size(380, 18)
    $pnlApp.Controls.Add($lblDesc)

    # Linha separadora sutil
    $sepApp = New-Object System.Windows.Forms.Panel
    $sepApp.Location  = New-Object System.Drawing.Point(4, 33)
    $sepApp.Size      = New-Object System.Drawing.Size(672, 1)
    $sepApp.BackColor = $corBorda
    $pnlApp.Controls.Add($sepApp)

    $pnlBlocoIndiv.Controls.Add($pnlApp)
    $script:chksIndividuais += $chk
    $yChk += 34
}

$alturaBloco2 = 4 + 14 + 24 + ($appsIndividuais.Count * 34) + 16
$pnlBlocoIndiv.Size = New-Object System.Drawing.Size(700, $alturaBloco2)
$pnlInstScroll.Controls.Add($pnlBlocoIndiv)

# --- Toolbar: contador + botao limpar + botao instalar ---
$pnlInstTop = New-Object System.Windows.Forms.Panel
$pnlInstTop.Dock      = "Top"
$pnlInstTop.Height    = 46
$pnlInstTop.BackColor = $corPainel

$pnlInstTop.Controls.Add($script:lblContadorInst)
$script:lblContadorInst.Location = New-Object System.Drawing.Point(16, 14)

$btnLimparInst = New-Object System.Windows.Forms.Button
$btnLimparInst.Text      = "Limpar Selecao"
$btnLimparInst.Location  = New-Object System.Drawing.Point(260, 9)
$btnLimparInst.Size      = New-Object System.Drawing.Size(130, 28)
$btnLimparInst.BackColor = $corBorda
$btnLimparInst.ForeColor = $corTexto
$btnLimparInst.FlatStyle = "Flat"
$btnLimparInst.FlatAppearance.BorderSize = 0
$btnLimparInst.add_Click({
    $script:chkBasicos.Checked = $false
    foreach ($chk in $script:chksIndividuais) { $chk.Checked = $false }
    Atualizar-ContadorInst
})
$pnlInstTop.Controls.Add($btnLimparInst)

# Botao instalar (dock bottom)
$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text      = "  Instalar Selecionados"
$btnInstalar.Dock      = "Bottom"
$btnInstalar.Height    = 46
$btnInstalar.BackColor = $corDestaque
$btnInstalar.ForeColor = $corTextoClaro
$btnInstalar.FlatStyle = "Flat"
$btnInstalar.FlatAppearance.BorderSize = 0
$btnInstalar.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$script:btnInstalar    = $btnInstalar

$btnInstalar.add_Click({
    # Montar lista de instalacoes
    $listaFinal = [System.Collections.ArrayList]@()

    if ($script:chkBasicos.Checked) {
        foreach ($app in $appsBasicos) {
            $listaFinal.Add($app) | Out-Null
        }
    }

    for ($i = 0; $i -lt $script:chksIndividuais.Count; $i++) {
        if ($script:chksIndividuais[$i].Checked) {
            $listaFinal.Add($appsIndividuais[$i]) | Out-Null
        }
    }

    if ($listaFinal.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Selecione ao menos um item para instalar.","Atencao","OK","Warning") | Out-Null
        return
    }

    $total = $listaFinal.Count
    $script:btnInstalar.Enabled = $false
    $script:btnInstalar.Text    = "Instalando... (0/$total)"

    Rodar-Async -Vars @{lista=$listaFinal; totalInst=$total} -Bloco {
        $n = 0
        foreach ($p in $lista) {
            $n++
            Escrever-Log "[$n/$totalInst] Instalando: $($p.Nome)..."
            try {
                & winget install --id $p.Winget --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
                    Escrever-Log "$($p.Nome) instalado!" "OK"
                } else {
                    Escrever-Log "Falha: $($p.Nome) (cod $LASTEXITCODE)" "ERRO"
                }
            } catch {
                Escrever-Log "Erro: $_" "ERRO"
            }
        }
        Escrever-Log "=== Instalacao concluida! ($n itens processados) ===" "OK"
    } -AoFinalizar {
        $script:btnInstalar.Enabled = $true
        $script:btnInstalar.Text    = "  Instalar Selecionados"
        $script:chkBasicos.Checked  = $false
        foreach ($chk in $script:chksIndividuais) { $chk.Checked = $false }
        Atualizar-ContadorInst
    }
})

$pInst.Controls.Add($pnlInstScroll)
$pInst.Controls.Add($pnlInstTop)
$pInst.Controls.Add($btnInstalar)

# =================================================================
#  ABA 1 - SISTEMA
# =================================================================
$pSis = $tabPanels[1]

$pnlSisScroll = New-Object System.Windows.Forms.Panel
$pnlSisScroll.Dock       = "Fill"
$pnlSisScroll.BackColor  = $corFundo
$pnlSisScroll.AutoScroll = $true

# Definicao das acoes do Sistema
# Removidos: Configurar DNS, Gerenc. de Disco, Informacoes (msinfo), Resetar TCP/IP
# Modificados: Limpeza de Disco (novo comando), Checar Disco (substitui Resetar TCP/IP)
$sisAcoes = @(
    @{
        Txt   = "Hardware Detalhado"
        Desc  = "CPU, RAM, slots, placa-mae, SSD/HD - tudo detalhado"
        Cor   = $corDestaque
        Cmd   = "hwinfo"
    }
    @{
        Txt   = "Limpeza de Disco"
        Desc  = "Remove arquivos temporarios, cache, Prefetch e SoftwareDistribution"
        Cor   = $corDestaque
        Cmd   = "limpeza"
    }
    @{
        Txt   = "SFC /scannow"
        Desc  = "Verifica e repara arquivos do sistema"
        Cor   = $corAmarelo
        Cmd   = "sfc"
    }
    @{
        Txt   = "DISM RestoreHealth"
        Desc  = "Repara imagem do Windows (pode demorar)"
        Cor   = $corAmarelo
        Cmd   = "dism"
    }
    @{
        Txt   = "Checar Disco (chkdsk)"
        Desc  = "Verifica integridade do disco C: com chkdsk /f /scan"
        Cor   = $corDestaque
        Cmd   = "chkdsk"
    }
    @{
        Txt   = "Flush DNS"
        Desc  = "Limpa cache DNS do sistema"
        Cor   = $corBorda
        Cmd   = "dns"
    }
    @{
        Txt   = "Reiniciar Explorer"
        Desc  = "Reinicia o Explorer sem reiniciar o PC"
        Cor   = $corBorda
        Cmd   = "exp"
    }
    @{
        Txt   = "Gerenc. de Tarefas"
        Desc  = "Abre o Gerenciador de Tarefas"
        Cor   = $corBorda
        Cmd   = "taskmgr"
    }
    @{
        Txt   = "Editor de Registro"
        Desc  = "Abre o Regedit"
        Cor   = $corBorda
        Cmd   = "regedit"
    }
    @{
        Txt   = "Windows Update"
        Desc  = "Abre as configuracoes do Windows Update"
        Cor   = $corBorda
        Cmd   = "wupd"
    }
    @{
        Txt   = "Reiniciar PC"
        Desc  = "Reinicia o computador imediatamente"
        Cor   = $corVermelho
        Cmd   = "reboot"
    }
)

$y = 14
foreach ($a in $sisAcoes) {
    $pnlRow = New-Object System.Windows.Forms.Panel
    $pnlRow.Location  = New-Object System.Drawing.Point(14, $y)
    $pnlRow.Size      = New-Object System.Drawing.Size(700, 54)
    $pnlRow.BackColor = $corPainel

    # Barra colorida lateral
    $barRow = New-Object System.Windows.Forms.Panel
    $barRow.Location  = New-Object System.Drawing.Point(0, 0)
    $barRow.Size      = New-Object System.Drawing.Size(4, 54)
    $barRow.BackColor = $a.Cor
    $pnlRow.Controls.Add($barRow)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = $a.Txt
    $btn.Location  = New-Object System.Drawing.Point(4, 0)
    $btn.Size      = New-Object System.Drawing.Size(190, 54)
    $btn.BackColor = $a.Cor
    $btn.ForeColor = if ($a.Cor.GetBrightness() -lt 0.6) { $corTextoClaro } else { $corTexto }
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.Tag       = $a.Cmd
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $a.Desc
    $lbl.Location  = New-Object System.Drawing.Point(204, 18)
    $lbl.Size      = New-Object System.Drawing.Size(488, 20)
    $lbl.ForeColor = $corTextoEscuro

    $btn.add_Click({
        switch ($this.Tag) {
            "hwinfo"  { Mostrar-HardwareInfo }
            "limpeza" {
                Escrever-Log "Iniciando limpeza de disco..."
                $cmdLimpeza = 'cmd /c "for %f in ("%TEMP%\*" "C:\Windows\Temp\*" "%APPDATA%\..\Local\Temp\*" "C:\Windows\Prefetch\*" "C:\Windows\SoftwareDistribution\Download\*") do del /f /q "%f" 2>nul & for /d %d in ("%TEMP%\*" "C:\Windows\Temp\*" "%APPDATA%\..\Local\CrashDumps\*") do rd /s /q "%d" 2>nul"'
                Start-Process "cmd.exe" -ArgumentList "/k $cmdLimpeza" -Verb RunAs
                Escrever-Log "Limpeza iniciada em terminal separado." "OK"
            }
            "sfc"     { Start-Process "cmd" -ArgumentList "/k sfc /scannow" -Verb RunAs; Escrever-Log "SFC iniciado..." "OK" }
            "dism"    { Start-Process "cmd" -ArgumentList "/k DISM /Online /Cleanup-Image /RestoreHealth" -Verb RunAs; Escrever-Log "DISM iniciado..." "OK" }
            "chkdsk"  {
                $r = [System.Windows.Forms.MessageBox]::Show(
                    "O chkdsk sera agendado para a proxima reinicializacao do Windows (disco C: em uso nao pode ser verificado imediatamente).`n`nContinuar?",
                    "Checar Disco", "YesNo", "Question")
                if ($r -eq "Yes") {
                    Start-Process "cmd" -ArgumentList "/k chkdsk C: /f /scan" -Verb RunAs
                    Escrever-Log "chkdsk C: /f /scan iniciado." "OK"
                }
            }
            "dns"     { & ipconfig /flushdns | Out-Null; Escrever-Log "Cache DNS limpo!" "OK" }
            "exp"     {
                Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
                Start-Sleep 1
                Start-Process "explorer"
                Escrever-Log "Explorer reiniciado!" "OK"
            }
            "taskmgr" { Start-Process "taskmgr" }
            "regedit" { Start-Process "regedit" -Verb RunAs }
            "wupd"    { Start-Process "ms-settings:windowsupdate" }
            "reboot"  {
                $r = [System.Windows.Forms.MessageBox]::Show("Reiniciar o computador agora?","Confirmar","YesNo","Warning")
                if ($r -eq "Yes") { Restart-Computer -Force }
            }
        }
    })

    $pnlRow.Controls.AddRange(@($btn, $lbl))
    $pnlSisScroll.Controls.Add($pnlRow)
    $y += 62
}

$pSis.Controls.Add($pnlSisScroll)

# =================================================================
#  FUNCAO: HARDWARE INFO (igual ao VicTool)
# =================================================================
function Mostrar-HardwareInfo {
    Escrever-Log "Coletando informacoes de hardware..."

    $frmHW = New-Object System.Windows.Forms.Form
    $frmHW.Text          = "JA Saude Animal - Hardware Detalhado"
    $frmHW.Size          = New-Object System.Drawing.Size(780, 680)
    $frmHW.StartPosition = "CenterScreen"
    $frmHW.BackColor     = $corFundo
    $frmHW.ForeColor     = $corTexto
    $frmHW.Font          = New-Object System.Drawing.Font("Segoe UI", 9)
    $frmHW.Icon          = Criar-Icone

    $pnlHWHeader = New-Object System.Windows.Forms.Panel
    $pnlHWHeader.Dock      = "Top"
    $pnlHWHeader.Height    = 46
    $pnlHWHeader.BackColor = $corPainel
    $lblHWTit = New-Object System.Windows.Forms.Label
    $lblHWTit.Text      = "Hardware Detalhado"
    $lblHWTit.Font      = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $lblHWTit.ForeColor = $corDestaque
    $lblHWTit.Location  = New-Object System.Drawing.Point(16, 10)
    $lblHWTit.AutoSize  = $true
    $pnlHWHeader.Controls.Add($lblHWTit)
    $frmHW.Controls.Add($pnlHWHeader)
    $frmHW.Show()
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $csInfo      = Get-CimInstance Win32_ComputerSystem | Select-Object -First 1
        $noDominio   = $csInfo.PartOfDomain
        $nomeDominio = if ($noDominio) { $csInfo.Domain } else { "Nao" }
        $tipoMembro  = if ($noDominio) { "Dominio: $($csInfo.Domain)" } else { "Grupo de trabalho: $($csInfo.Workgroup)" }

        $cpu         = Get-CimInstance Win32_Processor | Select-Object -First 1
        $cpuNome     = $cpu.Name.Trim()
        $cpuCores    = $cpu.NumberOfCores
        $cpuThreads  = $cpu.NumberOfLogicalProcessors
        $cpuClockMHz = $cpu.MaxClockSpeed
        $cpuClockGHz = [math]::Round($cpuClockMHz / 1000, 2)
        $cpuSocket   = $cpu.SocketDesignation
        $cpuArch     = $cpu.Architecture
        $archStr     = switch($cpuArch){0{"x86"};5{"ARM"};9{"x64"};12{"ARM64"};default{"Desconhecido"}}

        $mb       = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
        $mbFabric = $mb.Manufacturer.Trim()
        $mbModel  = $mb.Product.Trim()
        $mbSerial = $mb.SerialNumber.Trim()
        $bios     = Get-CimInstance Win32_BIOS | Select-Object -First 1
        $biosVer  = "$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)"

        $ramSlots    = Get-CimInstance Win32_PhysicalMemory
        $ramTotalGB  = [math]::Round(($ramSlots | Measure-Object Capacity -Sum).Sum / 1GB, 1)
        $slotsUsados = $ramSlots.Count
        $slotsTotais = (Get-CimInstance Win32_PhysicalMemoryArray | Select-Object -First 1).MemoryDevices
        $ramTipo     = ($ramSlots | Select-Object -First 1).MemoryType
        $tipoStr     = switch($ramTipo){20{"DDR"};21{"DDR2"};24{"DDR3"};26{"DDR4"};34{"DDR5"};default{"DDR?"}}
        if($tipoStr -eq "DDR?"){
            $smb = ($ramSlots | Select-Object -First 1).SMBIOSMemoryType
            $tipoStr = switch($smb){26{"DDR4"};34{"DDR5"};24{"DDR3"};21{"DDR2"};20{"DDR"};default{"Desconhecido"}}
        }
        $ramFreqMHz = ($ramSlots | Select-Object -First 1).ConfiguredClockSpeed
        if(!$ramFreqMHz -or $ramFreqMHz -eq 0){ $ramFreqMHz = ($ramSlots | Select-Object -First 1).Speed }

        $gpus = Get-CimInstance Win32_VideoController

        $allDiskToPart  = Get-CimInstance Win32_DiskDriveToDiskPartition
        $allPartToLogic = Get-CimInstance Win32_LogicalDiskToPartition
        $allLogicDisks  = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $allPhysDisk    = Get-PhysicalDisk -ErrorAction SilentlyContinue

        $discos = Get-CimInstance Win32_DiskDrive | ForEach-Object {
            $disco  = $_
            $sizeGB = [math]::Round($disco.Size / 1GB, 1)
            $model  = $disco.Model.Trim()
            $tipo   = "HDD"
            try {
                $pd = $allPhysDisk | Where-Object { $_.DeviceId -eq $disco.Index } | Select-Object -First 1
                if ($pd) {
                    $tipo = switch($pd.MediaType){"SSD"{"SSD"};"HDD"{"HDD"};default{"HDD"}}
                }
            } catch {}

            $partsFisicas = $allDiskToPart | Where-Object {
                $_.Antecedent.ToString() -match "Disk #$($disco.Index)[^0-9]|Disk #$($disco.Index)"""
            }
            $particoesInfo = [System.Collections.ArrayList]@()
            foreach ($pf in $partsFisicas) {
                $partDevID = $pf.Dependent.DeviceID
                $logRels   = $allPartToLogic | Where-Object { $_.Antecedent.ToString() -like "*$partDevID*" }
                foreach ($lr in $logRels) {
                    $letra  = $lr.Dependent.DeviceID
                    $ldisk  = $allLogicDisks | Where-Object { $_.DeviceID -eq $letra } | Select-Object -First 1
                    if ($ldisk -and $ldisk.Size -gt 0) {
                        $totGB  = [math]::Round($ldisk.Size / 1GB, 1)
                        $livGB  = [math]::Round($ldisk.FreeSpace / 1GB, 1)
                        $usaGB  = [math]::Round(($ldisk.Size - $ldisk.FreeSpace) / 1GB, 1)
                        $usaPct = [math]::Round((($ldisk.Size - $ldisk.FreeSpace) / $ldisk.Size) * 100, 1)
                        $particoesInfo.Add([PSCustomObject]@{Letra=$letra;TotGB=$totGB;UsaGB=$usaGB;LivGB=$livGB;UsaPct=$usaPct}) | Out-Null
                    }
                }
            }
            [PSCustomObject]@{Model=$model;SizeGB=$sizeGB;Tipo=$tipo;Interface=$disco.InterfaceType;Particoes=$particoesInfo}
        }

        $netAdapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
    } catch {
        $frmHW.Text = "Erro ao coletar hardware: $_"
        Escrever-Log "Erro ao coletar hardware: $_" "ERRO"
        return
    }

    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Location   = New-Object System.Drawing.Point(0, 46)
    $scroll.Size       = New-Object System.Drawing.Size(780, 584)
    $scroll.Anchor     = "Top,Left,Bottom,Right"
    $scroll.AutoScroll = $true
    $scroll.BackColor  = $corFundo
    $frmHW.Controls.Add($scroll)

    $script:yCard = 10

    function Novo-Card {
        param([string]$Titulo, [string[]]$Linhas, [System.Drawing.Color]$CorAcento)
        $linhasValidas = $Linhas | Where-Object { $_ -ne $null -and $_.Trim() -ne "" }
        $altura = 36 + ($linhasValidas.Count * 22) + 10

        $card = New-Object System.Windows.Forms.Panel
        $card.Location  = New-Object System.Drawing.Point(10, $script:yCard)
        $card.Size      = New-Object System.Drawing.Size(740, $altura)
        $card.BackColor = $corPainel

        $acento = New-Object System.Windows.Forms.Panel
        $acento.Location  = New-Object System.Drawing.Point(0, 0)
        $acento.Size      = New-Object System.Drawing.Size(4, $altura)
        $acento.BackColor = $CorAcento
        $card.Controls.Add($acento)

        $lblTit = New-Object System.Windows.Forms.Label
        $lblTit.Text      = $Titulo
        $lblTit.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $lblTit.ForeColor = $CorAcento
        $lblTit.Location  = New-Object System.Drawing.Point(14, 8)
        $lblTit.AutoSize  = $true
        $card.Controls.Add($lblTit)

        $yLinha = 32
        foreach ($linha in $linhasValidas) {
            $partes = $linha -split "\|", 2
            $chave  = $partes[0].Trim()
            $valor  = if ($partes.Count -gt 1) { $partes[1].Trim() } else { "" }

            $lblChave = New-Object System.Windows.Forms.Label
            $lblChave.Text      = $chave
            $lblChave.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
            $lblChave.ForeColor = $corTextoEscuro
            $lblChave.Location  = New-Object System.Drawing.Point(14, $yLinha)
            $lblChave.Size      = New-Object System.Drawing.Size(200, 20)
            $card.Controls.Add($lblChave)

            $lblValor = New-Object System.Windows.Forms.Label
            $lblValor.Text      = $valor
            $lblValor.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $lblValor.ForeColor = $corTexto
            $lblValor.Location  = New-Object System.Drawing.Point(218, $yLinha)
            $lblValor.Size      = New-Object System.Drawing.Size(510, 20)
            $card.Controls.Add($lblValor)

            $yLinha += 22
        }

        $scroll.Controls.Add($card)
        $script:yCard += $altura + 10
    }

    $so = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $so.LastBootUpTime
    $uptimeStr = "{0}d {1}h {2}m" -f [int]$uptime.TotalDays, $uptime.Hours, $uptime.Minutes
    $dominioLinha = if ($noDominio) { "Dominio | $nomeDominio" } else { "Dominio | Nao ingressado ($tipoMembro)" }

    Novo-Card -Titulo "Sistema Operacional" -CorAcento $corDestaque -Linhas @(
        "Computador | $env:COMPUTERNAME",
        $dominioLinha,
        "Sistema    | $($so.Caption) $($so.OSArchitecture)",
        "Build      | $($so.BuildNumber) ($($so.Version))",
        "Instalado  | $($so.InstallDate.ToString('dd/MM/yyyy'))",
        "Ultimo boot| $($so.LastBootUpTime.ToString('dd/MM/yyyy HH:mm'))  (uptime: $uptimeStr)"
    )

    Novo-Card -Titulo "Placa-Mae" -CorAcento $corAmarelo -Linhas @(
        "Fabricante | $mbFabric",
        "Modelo     | $mbModel",
        "Serial     | $mbSerial",
        "BIOS       | $biosVer",
        "Socket CPU | $cpuSocket"
    )

    Novo-Card -Titulo "Processador (CPU)" -CorAcento $corDestaque -Linhas @(
        "Modelo       | $cpuNome",
        "Arquitetura  | $archStr",
        "Nucleos      | $cpuCores nucleos / $cpuThreads threads",
        "Clock Maximo | $cpuClockGHz GHz ($cpuClockMHz MHz)",
        "Socket       | $cpuSocket"
    )

    $ramLinhas = @(
        "Total     | $ramTotalGB GB",
        "Tipo      | $tipoStr",
        "Frequencia| $ramFreqMHz MHz",
        "Slots     | $slotsUsados de $slotsTotais slots"
    )
    $idx = 1
    foreach ($slot in $ramSlots) {
        $capGB = [math]::Round($slot.Capacity/1GB,1)
        $fab   = if($slot.Manufacturer.Trim()) {$slot.Manufacturer.Trim()} else {"N/A"}
        $freq  = if($slot.ConfiguredClockSpeed -gt 0){$slot.ConfiguredClockSpeed}else{$slot.Speed}
        $ramLinhas += "Modulo $idx (${capGB}GB) | Fab: $fab  Freq: $freq MHz  Banco: $($slot.DeviceLocator)"
        $idx++
    }
    Novo-Card -Titulo "Memoria RAM" -CorAcento $corAmarelo -Linhas $ramLinhas

    $gpuLinhas = @()
    foreach($g in $gpus){
        $vramGB = if($g.AdapterRAM -gt 0){ [math]::Round($g.AdapterRAM/1GB,1) }else{"N/A"}
        $gpuLinhas += "Nome      | $($g.Name.Trim())"
        $gpuLinhas += "VRAM      | $vramGB GB"
        $gpuLinhas += "Driver    | $($g.DriverVersion)"
    }
    Novo-Card -Titulo "Placa de Video (GPU)" -CorAcento $corDestaque -Linhas $gpuLinhas

    foreach ($d in $discos) {
        $discoLinhas = @(
            "Modelo     | $($d.Model)",
            "Tipo       | $($d.Tipo)",
            "Interface  | $($d.Interface)",
            "Capacidade | $($d.SizeGB) GB"
        )
        foreach ($part in $d.Particoes) {
            if ($part.TotGB -gt 0) {
                $barLen = 20
                $filled = [math]::Round($barLen * ($part.UsaPct / 100))
                $bar    = ("#" * $filled) + ("-" * ($barLen - $filled))
                $discoLinhas += "Particao $($part.Letra) | Total: $($part.TotGB) GB  Usado: $($part.UsaGB) GB ($($part.UsaPct)%)  Livre: $($part.LivGB) GB  [$bar]"
            }
        }
        Novo-Card -Titulo "Armazenamento - $($d.Model) [$($d.Tipo)]" -CorAcento $corDestaque -Linhas $discoLinhas
    }

    $netLinhas = @()
    foreach($n in $netAdapters){
        $ips = ($n.IPAddress | Where-Object {$_ -match "\."}) -join ", "
        $netLinhas += "Adaptador | $($n.Description)"
        $netLinhas += "IP        | $ips"
        $netLinhas += "Gateway   | $(($n.DefaultIPGateway | Select-Object -First 1))"
        $netLinhas += "DNS       | $(($n.DNSServerSearchOrder | Select-Object -First 2) -join ', ')"
        $netLinhas += "MAC       | $($n.MACAddress)"
    }
    Novo-Card -Titulo "Rede" -CorAcento $corAmarelo -Linhas $netLinhas

    # Botao exportar
    $pnlBotoes = New-Object System.Windows.Forms.Panel
    $pnlBotoes.Location  = New-Object System.Drawing.Point(0, 586)
    $pnlBotoes.Size      = New-Object System.Drawing.Size(780, 50)
    $pnlBotoes.Anchor    = "Bottom,Left,Right"
    $pnlBotoes.BackColor = $corPainel

    # Montar relatorio
    $script:hwNomeMaquina = $env:COMPUTERNAME
    $relLinhas = @("================================================================")
    $relLinhas += "  JA Saude Animal - Relatorio de Hardware"
    $relLinhas += "  Gerado em : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    $relLinhas += "  Maquina   : $env:COMPUTERNAME  |  Usuario: $env:USERNAME"
    $relLinhas += "================================================================"
    $relLinhas += "  SO: $($so.Caption) $($so.OSArchitecture)  Build: $($so.BuildNumber)"
    $relLinhas += "  CPU: $cpuNome  [$cpuCores cores / $cpuThreads threads / $cpuClockGHz GHz]"
    $relLinhas += "  RAM: $ramTotalGB GB $tipoStr @ $ramFreqMHz MHz  ($slotsUsados/$slotsTotais slots)"
    $relLinhas += "  MB : $mbFabric $mbModel  BIOS: $biosVer"
    foreach ($g in $gpus) { $relLinhas += "  GPU: $($g.Name.Trim())" }
    foreach ($d in $discos) {
        $relLinhas += "  Disco: $($d.Model) [$($d.Tipo)] $($d.SizeGB) GB"
        foreach ($part in $d.Particoes) {
            if($part.TotGB -gt 0) { $relLinhas += "    $($part.Letra) : $($part.TotGB) GB total | $($part.UsaGB) GB usado ($($part.UsaPct)%) | $($part.LivGB) GB livre" }
        }
    }
    $relLinhas += "================================================================"
    $script:hwRelatorio = $relLinhas -join "`r`n"

    $btnCopiar = New-Object System.Windows.Forms.Button
    $btnCopiar.Text     = "Copiar para Area de Transferencia"
    $btnCopiar.Location = New-Object System.Drawing.Point(8, 8)
    $btnCopiar.Size     = New-Object System.Drawing.Size(260, 34)
    $btnCopiar.BackColor= $corBorda; $btnCopiar.ForeColor = $corTexto
    $btnCopiar.FlatStyle= "Flat"; $btnCopiar.FlatAppearance.BorderSize = 0
    $btnCopiar.Font     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnCopiar.add_Click({
        [System.Windows.Forms.Clipboard]::SetText($script:hwRelatorio)
        [System.Windows.Forms.MessageBox]::Show("Relatorio copiado!", "Copiado", "OK", "Information") | Out-Null
    })

    $btnExportar = New-Object System.Windows.Forms.Button
    $btnExportar.Text     = "Exportar .TXT para Area de Trabalho"
    $btnExportar.Location = New-Object System.Drawing.Point(278, 8)
    $btnExportar.Size     = New-Object System.Drawing.Size(280, 34)
    $btnExportar.BackColor= $corDestaque; $btnExportar.ForeColor = $corTextoClaro
    $btnExportar.FlatStyle= "Flat"; $btnExportar.FlatAppearance.BorderSize = 0
    $btnExportar.Font     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnExportar.add_Click({
        try {
            $dataHora    = Get-Date -Format "yyyy-MM-dd_HH-mm"
            $nomeArq     = "Hardware_$($script:hwNomeMaquina)_${dataHora}.txt"
            $desktop     = [System.Environment]::GetFolderPath("Desktop")
            $caminho     = Join-Path $desktop $nomeArq
            $script:hwRelatorio | Out-File -FilePath $caminho -Encoding UTF8 -Force
            Escrever-Log "Exportado: $caminho" "OK"
            $resp = [System.Windows.Forms.MessageBox]::Show("Salvo com sucesso!`n`n$caminho`n`nAbrir agora?","Exportado!","YesNo","Information")
            if ($resp -eq "Yes") { Start-Process "notepad.exe" -ArgumentList "`"$caminho`"" }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erro ao exportar: $_","Erro","OK","Error") | Out-Null
        }
    })

    $pnlBotoes.Controls.AddRange(@($btnCopiar, $btnExportar))
    $frmHW.Controls.Add($pnlBotoes)
    Escrever-Log "Hardware coletado com sucesso!" "OK"
}

# =================================================================
#  LOG PANEL
# =================================================================
$lblLogTit = New-Object System.Windows.Forms.Label
$lblLogTit.Text      = "LOG"
$lblLogTit.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$lblLogTit.ForeColor = $corTextoEscuro
$lblLogTit.Location  = New-Object System.Drawing.Point(0, 4)
$lblLogTit.AutoSize  = $true

$script:txtLog = New-Object System.Windows.Forms.RichTextBox
$script:txtLog.Location    = New-Object System.Drawing.Point(0, 22)
$script:txtLog.Size        = New-Object System.Drawing.Size(239, 600)
$script:txtLog.BackColor   = $corPainel
$script:txtLog.ForeColor   = $corDestaque
$script:txtLog.Font        = New-Object System.Drawing.Font("Consolas", 8)
$script:txtLog.ReadOnly    = $true
$script:txtLog.BorderStyle = "None"
$script:txtLog.ScrollBars  = "Vertical"
$script:txtLog.Anchor      = "Top,Left,Bottom,Right"

$btnLimLog = New-Object System.Windows.Forms.Button
$btnLimLog.Text      = "Limpar Log"
$btnLimLog.Location  = New-Object System.Drawing.Point(0, 626)
$btnLimLog.Size      = New-Object System.Drawing.Size(239, 28)
$btnLimLog.BackColor = $corBorda
$btnLimLog.ForeColor = $corTextoEscuro
$btnLimLog.FlatStyle = "Flat"
$btnLimLog.FlatAppearance.BorderSize = 0
$btnLimLog.add_Click({ $script:txtLog.Clear() })

$pnlLog.Controls.AddRange(@($lblLogTit, $script:txtLog, $btnLimLog))

# =================================================================
#  FOOTER
# =================================================================
$pnlFoot = New-Object System.Windows.Forms.Panel
$pnlFoot.Dock      = "Bottom"
$pnlFoot.Height    = 26
$pnlFoot.BackColor = $corPainel

$lblFoot = New-Object System.Windows.Forms.Label
$lblFoot.Text      = "JA Saude Animal  |  Ferramenta de TI v1.0  |  Executando como Administrador"
$lblFoot.ForeColor = $corTextoEscuro
$lblFoot.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblFoot.Location  = New-Object System.Drawing.Point(10, 6)
$lblFoot.AutoSize  = $true
$pnlFoot.Controls.Add($lblFoot)
$script:form.Controls.Add($pnlFoot)

# =================================================================
#  INICIAR
# =================================================================
$script:form.add_Shown({
    Selecionar-Tab -idx 0
    Escrever-Log "JA Saude Animal - Ferramenta de TI iniciada!"
    Escrever-Log "SO: $([System.Environment]::OSVersion.VersionString)"
    Escrever-Log "Usuario: $env:USERNAME @ $env:COMPUTERNAME"
    Escrever-Log "Pronto para uso."
})

[System.Windows.Forms.Application]::Run($script:form)
