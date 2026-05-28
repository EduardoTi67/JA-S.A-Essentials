# ============================================================
#  JA Saude Animal - Ferramenta de TI (UX/UI Edition 2026)
#  Reestruturado com TableLayoutPanel (Anti-Sobreposicao)
# ============================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Paleta de Cores Modernizada (Minimalismo Corporativo) ---
$cBgGlobal   = [System.Drawing.Color]::FromArgb(246, 248, 250)
$cBgCard     = [System.Drawing.Color]::FromArgb(255, 255, 255)
$cBrand      = [System.Drawing.Color]::FromArgb(35, 134, 85)
$cBrandHov   = [System.Drawing.Color]::FromArgb(28, 107, 68)
$cTextDark   = [System.Drawing.Color]::FromArgb(31, 35, 40)
$cTextMuted  = [System.Drawing.Color]::FromArgb(101, 109, 118)
$cBorder     = [System.Drawing.Color]::FromArgb(208, 215, 222)
$cTerminalBg = [System.Drawing.Color]::FromArgb(13, 17, 23)
$cTerminalTx = [System.Drawing.Color]::FromArgb(86, 211, 100)
$cSidebarBg  = [System.Drawing.Color]::FromArgb(22, 27, 34)

# --- Logica de Thread Segura ---
$script:syncHash = [hashtable]::Synchronized(@{
    LogQueue = [System.Collections.Generic.Queue[string]]::new()
})

function Escrever-Log {
    param([string]$Msg, [string]$Tipo = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $linha = "[$ts] [$Tipo] $Msg"
    $script:syncHash.LogQueue.Enqueue($linha)
}

function Rodar-Async {
    param([ScriptBlock]$Bloco, [hashtable]$Vars = @{}, [ScriptBlock]$AoFinalizar = $null)
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"; $rs.ThreadOptions = "ReuseThread"; $rs.Open()
    foreach ($k in $Vars.Keys) { $rs.SessionStateProxy.SetVariable($k, $Vars[$k]) }
    $rs.SessionStateProxy.SetVariable("syncHash", $script:syncHash)
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript({
        function Escrever-Log {
            param($m, $t="INFO")
            $ts = Get-Date -Format "HH:mm:ss"
            $syncHash.LogQueue.Enqueue("[$ts] [$t] $m")
        }
    }) | Out-Null
    $ps.AddScript($Bloco) | Out-Null
    $handle = $ps.BeginInvoke()
    
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 300
    $timer.add_Tick({
        if (-not $handle.IsCompleted) { return }
        $timer.Stop(); $timer.Dispose()
        try { $ps.EndInvoke($handle) } catch {}
        try { $ps.Dispose(); $rs.Close(); $rs.Dispose() } catch {}
        if ($AoFinalizar) { & $AoFinalizar }
    })
    $timer.Start()
}

# --- Base de Dados de Apps ---
$appsBasicos = @(
    @{ Nome="Firefox";                  Winget="Mozilla.Firefox" }
    @{ Nome="Google Chrome";            Winget="Google.Chrome" }
    @{ Nome="Microsoft Edge";           Winget="Microsoft.Edge" }
    @{ Nome="7-Zip";                    Winget="7zip.7zip" }
    @{ Nome="VC Redist All (x86/x64)";  Winget="Microsoft.VCRedist.2015+.x64" }
    @{ Nome=".NET Desktop Runtime 8/9"; Winget="Microsoft.DotNet.DesktopRuntime.8" }
    @{ Nome="OneDrive";                 Winget="Microsoft.OneDrive" }
    @{ Nome="Zoom";                     Winget="Zoom.Zoom" }
    @{ Nome="Microsoft Teams";          Winget="Microsoft.Teams" }
    @{ Nome="TeamViewer 15";            Winget="TeamViewer.TeamViewer" }
)

$appsIndividuais = @(
    @{ Nome="Adobe Acrobat Reader 64"; Winget="Adobe.Acrobat.Reader.64-bit";  Desc="Leitor de PDF oficial (Padrão)" }
    @{ Nome="FortiClient VPN Only";    Winget="Fortinet.FortiClientVPN";       Desc="Cliente para acesso remoto seguro" }
    @{ Nome="Microsoft Office 365";    Winget="Microsoft.Office";              Desc="Pacote Office Online / Local" }
    @{ Nome="PDF24 Creator";           Winget="geeksoftwareGmbH.PDF24Creator";  Desc="Ferramenta gratuita para mesclar/editar PDF" }
    @{ Nome="Java 8 (JRE)";            Winget="Oracle.JavaRuntimeEnvironment";  Desc="Ambiente de execucao Java legado" }
    @{ Nome="VLC Media Player";        Winget="VideoLAN.VLC";                   Desc="Reprodutor universal de video" }
)

# =================================================================
# JANELA PRINCIPAL
# =================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text          = "JA Saude Animal | Workstation Setup 2.0"
$form.Size          = New-Object System.Drawing.Size(1280, 760)
$form.StartPosition = "CenterScreen"
$form.BackColor     = $cBgGlobal
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 9.5)
$form.MinimumSize   = New-Object System.Drawing.Size(1100, 720)

# Header Topo
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock = "Top"; $pnlHeader.Height = 70; $pnlHeader.BackColor = $cBgCard
$pnlHeader.Padding = New-Object System.Windows.Forms.Padding(20, 15, 20, 15)

$lblBrand = New-Object System.Windows.Forms.Label
$lblBrand.Text = "JA SAUDE ANIMAL"
$lblBrand.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblBrand.ForeColor = $cBrand
$lblBrand.Dock = "Left"
$lblBrand.AutoSize = $true

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "  |  Implantacao & Reparos de TI"
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$lblSub.ForeColor = $cTextMuted
$lblSub.Dock = "Left"
$lblSub.AutoSize = $true
$lblSub.Padding = New-Object System.Windows.Forms.Padding(0, 6, 0, 0)

$pnlHeader.Controls.Add($lblSub)
$pnlHeader.Controls.Add($lblBrand)
$form.Controls.Add($pnlHeader)

# Borda do header
$pnlBorder = New-Object System.Windows.Forms.Panel
$pnlBorder.Dock = "Top"; $pnlBorder.Height = 1; $pnlBorder.BackColor = $cBorder
$form.Controls.Add($pnlBorder)

# =================================================================
# O SEGREDO ANTI-SOBREPOSIÇÃO: TableLayoutPanel
# =================================================================
$gridMain = New-Object System.Windows.Forms.TableLayoutPanel
$gridMain.Dock = "Fill"
$gridMain.ColumnCount = 3
$gridMain.RowCount = 1
# Coluna 1 (Menu Esquerdo): 240px Fixo
$gridMain.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 240))) | Out-Null
# Coluna 2 (Centro): 100% do que sobrar
$gridMain.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
# Coluna 3 (Terminal): 320px Fixo
$gridMain.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 320))) | Out-Null
$form.Controls.Add($gridMain)

# 1. Sidebar
$pnlSidebar = New-Object System.Windows.Forms.Panel
$pnlSidebar.Dock = "Fill"; $pnlSidebar.BackColor = $cSidebarBg
$pnlSidebar.Margin = New-Object System.Windows.Forms.Padding(0)
$pnlSidebar.Padding = New-Object System.Windows.Forms.Padding(10, 20, 10, 20)
$gridMain.Controls.Add($pnlSidebar, 0, 0)

# 2. Content Central
$pnlContent = New-Object System.Windows.Forms.Panel
$pnlContent.Dock = "Fill"; $pnlContent.BackColor = $cBgGlobal
$pnlContent.Margin = New-Object System.Windows.Forms.Padding(0)
$gridMain.Controls.Add($pnlContent, 1, 0)

# 3. Terminal Direita
$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.Dock = "Fill"; $pnlLog.BackColor = $cBgGlobal
$pnlLog.Margin = New-Object System.Windows.Forms.Padding(0)
$pnlLog.Padding = New-Object System.Windows.Forms.Padding(15)
$gridMain.Controls.Add($pnlLog, 2, 0)

# =================================================================
# SISTEMA DE ABAS
# =================================================================
$tabPanels  = [System.Collections.ArrayList]@()
$tabButtons = [System.Collections.ArrayList]@()

function Selecionar-Tab($idx) {
    for ($i=0; $i -lt $tabPanels.Count; $i++) { $tabPanels[$i].Visible = ($i -eq $idx) }
    for ($i=0; $i -lt $tabButtons.Count; $i++) {
        if ($i -eq $idx) {
            $tabButtons[$i].BackColor = $cBrand
            $tabButtons[$i].ForeColor = $cBgCard
        } else {
            $tabButtons[$i].BackColor = $cSidebarBg
            $tabButtons[$i].ForeColor = $cBorder
        }
    }
}

$tabs = @( @{Name="  Instalacao em Lote"}, @{Name="  Manutencao do Sistema"} )

$flowSidebar = New-Object System.Windows.Forms.FlowLayoutPanel
$flowSidebar.Dock = "Fill"; $flowSidebar.FlowDirection = "TopDown"; $flowSidebar.WrapContents = $false
$pnlSidebar.Controls.Add($flowSidebar)

foreach ($t in $tabs) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $t.Name
    $btn.Width = 220; $btn.Height = 50
    $btn.FlatStyle = "Flat"; $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.TextAlign = "MiddleLeft"; $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Tag = $tabButtons.Count
    $btn.add_Click({ Selecionar-Tab $this.Tag })
    $flowSidebar.Controls.Add($btn)
    $tabButtons.Add($btn) | Out-Null
    
    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Dock = "Fill"; $pnl.Visible = $false
    $pnl.Padding = New-Object System.Windows.Forms.Padding(30) 
    $pnlContent.Controls.Add($pnl)
    $tabPanels.Add($pnl) | Out-Null
}

# =================================================================
# ABA 0: INSTALACAO
# =================================================================
$abaInst = $tabPanels[0]

$pnlInstTop = New-Object System.Windows.Forms.Panel
$pnlInstTop.Dock = "Top"; $pnlInstTop.Height = 40
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Nenhum aplicativo selecionado."
$lblStatus.Dock = "Left"; $lblStatus.AutoSize = $true
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblStatus.ForeColor = $cTextMuted

$btnLimpar = New-Object System.Windows.Forms.Button
$btnLimpar.Text = "Limpar Selecao"
$btnLimpar.Dock = "Right"; $btnLimpar.Width = 120
$btnLimpar.FlatStyle = "Flat"; $btnLimpar.FlatAppearance.BorderColor = $cBorder
$btnLimpar.BackColor = $cBgCard; $btnLimpar.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnLimpar.add_Click({
    $script:chkBasicos.Checked = $false
    foreach ($c in $script:chkIndiv) { $c.Checked = $false }
    Atualizar-Contador
})
$pnlInstTop.Controls.Add($lblStatus)
$pnlInstTop.Controls.Add($btnLimpar)
$abaInst.Controls.Add($pnlInstTop)

$flowInst = New-Object System.Windows.Forms.FlowLayoutPanel
$flowInst.Dock = "Fill"; $flowInst.FlowDirection = "TopDown"; $flowInst.WrapContents = $false
$flowInst.AutoScroll = $true
$flowInst.Padding = New-Object System.Windows.Forms.Padding(0, 15, 0, 15)
$abaInst.Controls.Add($flowInst)

function Atualizar-Contador {
    $c = 0
    if ($script:chkBasicos.Checked) { $c += $appsBasicos.Count }
    foreach ($chk in $script:chkIndiv) { if ($chk.Checked) { $c++ } }
    
    $lblStatus.Text = if ($c -gt 0) { "$c item(ns) na fila de instalacao" } else { "Nenhum aplicativo selecionado." }
    $lblStatus.ForeColor = if ($c -gt 0) { $cBrand } else { $cTextMuted }
    $script:btnInstalar.Enabled = ($c -gt 0)
}

function Criar-CardBox($Titulo, $Desc, $Altura) {
    $card = New-Object System.Windows.Forms.Panel
    $card.Width = 600; $card.Height = $Altura
    $card.BackColor = $cBgCard
    $card.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 20)
    
    $borda = New-Object System.Windows.Forms.Panel
    $borda.Dock = "Left"; $borda.Width = 4; $borda.BackColor = $cBrand
    $card.Controls.Add($borda)
    
    $t = New-Object System.Windows.Forms.Label
    $t.Text = $Titulo; $t.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $t.Location = New-Object System.Drawing.Point(20, 15); $t.AutoSize = $true
    
    $d = New-Object System.Windows.Forms.Label
    $d.Text = $Desc; $d.ForeColor = $cTextMuted
    $d.Location = New-Object System.Drawing.Point(20, 40); $d.Size = New-Object System.Drawing.Size(560, 40)
    
    $card.Controls.Add($t); $card.Controls.Add($d)
    return $card
}

$cardBase = Criar-CardBox "Kit Standard Corporativo" "Instala navegadores, compactador, Runtimes .NET, C++ Redist e ferramentas de comunicacao em lote." 140
$script:chkBasicos = New-Object System.Windows.Forms.CheckBox
$script:chkBasicos.Text = "Selecionar todos os aplicativos do Kit Standard"
$script:chkBasicos.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:chkBasicos.ForeColor = $cBrand
$script:chkBasicos.Location = New-Object System.Drawing.Point(20, 90); $script:chkBasicos.AutoSize = $true
$script:chkBasicos.Cursor = [System.Windows.Forms.Cursors]::Hand
$script:chkBasicos.add_CheckedChanged({ Atualizar-Contador })
$cardBase.Controls.Add($script:chkBasicos)
$flowInst.Controls.Add($cardBase)

$cardIndiv = Criar-CardBox "Softwares Especificos" "Marque apenas o que o usuario precisa:" ($appsIndividuais.Count * 35 + 90)
$script:chkIndiv = @()
$yP = 80
foreach ($app in $appsIndividuais) {
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text = $app.Nome; $c.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $c.Location = New-Object System.Drawing.Point(20, $yP); $c.Width = 200
    $c.Cursor = [System.Windows.Forms.Cursors]::Hand
    $c.add_CheckedChanged({ Atualizar-Contador })
    
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $app.Desc; $l.ForeColor = $cTextMuted
    # ======================================================
    # O PROBLEMA MATEMÁTICO ANTERIOR ESTÁ CORRIGIDO AQUI:
    # ======================================================
    $l.Location = New-Object System.Drawing.Point(220, ($yP + 3))
    $l.Width = 350
    
    $cardIndiv.Controls.Add($c); $cardIndiv.Controls.Add($l)
    $script:chkIndiv += $c
    $yP += 35
}
$flowInst.Controls.Add($cardIndiv)

$pnlFooterInst = New-Object System.Windows.Forms.Panel
$pnlFooterInst.Dock = "Bottom"; $pnlFooterInst.Height = 60
$script:btnInstalar = New-Object System.Windows.Forms.Button
$script:btnInstalar.Text = "Iniciar Instalacao --->"
$script:btnInstalar.Dock = "Fill"
$script:btnInstalar.BackColor = $cBrand; $script:btnInstalar.ForeColor = $cBgCard
$script:btnInstalar.FlatStyle = "Flat"; $script:btnInstalar.FlatAppearance.BorderSize = 0
$script:btnInstalar.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$script:btnInstalar.Cursor = [System.Windows.Forms.Cursors]::Hand
$script:btnInstalar.Enabled = $false

$script:btnInstalar.add_Click({
    $lista = [System.Collections.ArrayList]@()
    if ($script:chkBasicos.Checked) { foreach ($a in $appsBasicos) { $lista.Add($a) | Out-Null } }
    for ($i=0; $i -lt $script:chkIndiv.Count; $i++) { if ($script:chkIndiv[$i].Checked) { $lista.Add($appsIndividuais[$i]) | Out-Null } }
    
    $script:btnInstalar.Enabled = $false
    $script:btnInstalar.Text = "Processando instalacao..."
    
    Rodar-Async -Vars @{Lista = $lista} -Bloco {
        Escrever-Log "=== INICIANDO IMPLANTACAO ===" "INFO"
        $tot = $Lista.Count; $i = 0
        foreach ($app in $Lista) {
            $i++
            Escrever-Log "[$i/$tot] Baixando: $($app.Nome)..." "PROG"
            $proc = Start-Process "winget" -ArgumentList "install --id $($app.Winget) --silent --accept-package-agreements --accept-source-agreements --scope machine" -Wait -NoNewWindow -PassThru
            if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq -1978335189) { Escrever-Log "$($app.Nome) OK!" "SUC" }
            else { Escrever-Log "Falha: $($app.Nome) (Cod: $($proc.ExitCode))" "ERR" }
        }
        Escrever-Log "=== CONCLUIDO ===" "INFO"
    } -AoFinalizar {
        $script:btnInstalar.Text = "Iniciar Instalacao --->"
        $script:chkBasicos.Checked = $false
        foreach ($c in $script:chkIndiv) { $c.Checked = $false }
        Atualizar-Contador
    }
})
$pnlFooterInst.Controls.Add($script:btnInstalar)
$abaInst.Controls.Add($pnlFooterInst)

# =================================================================
# ABA 1: SISTEMA E REPAROS
# =================================================================
$abaSis = $tabPanels[1]

$lblSisTop = New-Object System.Windows.Forms.Label
$lblSisTop.Text = "Acoes Rapidas de Sistema"
$lblSisTop.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblSisTop.ForeColor = $cTextDark
$lblSisTop.Dock = "Top"; $lblSisTop.Height = 50
$abaSis.Controls.Add($lblSisTop)

$flowSis = New-Object System.Windows.Forms.FlowLayoutPanel
$flowSis.Dock = "Fill"
$flowSis.FlowDirection = "LeftToRight"
$flowSis.AutoScroll = $true
$abaSis.Controls.Add($flowSis)

$cmds = @(
    @{ Txt="Limpeza Profunda"; Desc="Expurga Temp, Prefetch e Logs"; Cmd="limp"; Cor=$cBrand }
    @{ Txt="Reparar SO (SFC)"; Desc="Verifica integridade do Windows"; Cmd="sfc"; Cor=[System.Drawing.Color]::Peru }
    @{ Txt="Restaurar Imagem"; Desc="DISM Online Cleanup"; Cmd="dism"; Cor=[System.Drawing.Color]::Peru }
    @{ Txt="Checar Disco"; Desc="Agenda Chkdsk para o boot"; Cmd="chk"; Cor=$cTextDark }
    @{ Txt="Flush DNS"; Desc="Renova tabelas locais de IP"; Cmd="dns"; Cor=$cTextDark }
    @{ Txt="Reiniciar Explorer"; Desc="Restaura interface grafica"; Cmd="exp"; Cor=$cTextDark }
    @{ Txt="Reiniciar PC"; Desc="Reboot forcado da maquina"; Cmd="rb"; Cor=[System.Drawing.Color]::Firebrick }
)

foreach ($c in $cmds) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Width = 280; $btn.Height = 85
    $btn.Margin = New-Object System.Windows.Forms.Padding(0, 0, 15, 15)
    $btn.BackColor = $cBgCard; $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderColor = $cBorder; $btn.FlatAppearance.BorderSize = 1
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.TextAlign = "TopLeft"
    $btn.Padding = New-Object System.Windows.Forms.Padding(10, 10, 10, 10)
    
    $btn.Text = "$($c.Txt)`n`n$($c.Desc)"
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $btn.ForeColor = $cTextMuted
    
    $colorStrip = New-Object System.Windows.Forms.Panel
    $colorStrip.BackColor = $c.Cor; $colorStrip.Width = 4; $colorStrip.Dock = "Left"
    $btn.Controls.Add($colorStrip)
    
    $btn.Tag = $c.Cmd
    $btn.add_Click({
        switch ($this.Tag) {
            "limp" { Start-Process "cmd" -ArgumentList "/c del /f /s /q %temp%\* & del /f /s /q C:\Windows\Temp\*" -WindowStyle Hidden; Escrever-Log "Limpeza executada!" "OK" }
            "sfc"  { Start-Process "cmd" -ArgumentList "/k sfc /scannow" -Verb RunAs; Escrever-Log "SFC /scannow aberto no terminal." }
            "dism" { Start-Process "cmd" -ArgumentList "/k DISM /Online /Cleanup-Image /RestoreHealth" -Verb RunAs; Escrever-Log "DISM iniciado." }
            "chk"  { Start-Process "cmd" -ArgumentList "/k chkdsk C: /f /r" -Verb RunAs; Escrever-Log "Confirme o agendamento no terminal." }
            "dns"  { & ipconfig /flushdns | Out-Null; Escrever-Log "Cache DNS limpo." "OK" }
            "exp"  { Stop-Process -Name explorer -Force; Start-Sleep 1; Start-Process explorer; Escrever-Log "Explorer reiniciado." }
            "rb"   { Restart-Computer -Force }
        }
    })
    $flowSis.Controls.Add($btn)
}

# =================================================================
# TERMINAL DE LOGS (Direita)
# =================================================================
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "TERMINAL DE TRABALHO"
$lblLog.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblLog.ForeColor = $cTextMuted
$lblLog.Dock = "Top"; $lblLog.Height = 30
$pnlLog.Controls.Add($lblLog)

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Dock = "Fill"
$txtLog.BackColor = $cTerminalBg
$txtLog.ForeColor = $cTerminalTx
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.BorderStyle = "None"
$txtLog.ReadOnly = $true
$pnlLog.Controls.Add($txtLog)

$uiTimer = New-Object System.Windows.Forms.Timer
$uiTimer.Interval = 100
$uiTimer.add_Tick({
    while ($script:syncHash.LogQueue.Count -gt 0) {
        $linha = $script:syncHash.LogQueue.Dequeue()
        $txtLog.AppendText("$linha`r`n")
        $txtLog.ScrollToCaret()
    }
})
$uiTimer.Start()

# =================================================================
# INICIALIZACAO
# =================================================================
$form.add_Shown({
    Selecionar-Tab 0
    Escrever-Log "JA Saude Animal UI 2026 inicializado." "SYS"
    Escrever-Log "Operando sob: $env:USERNAME" "SYS"
})

$form.ShowDialog() | Out-Null
$uiTimer.Stop(); $uiTimer.Dispose()