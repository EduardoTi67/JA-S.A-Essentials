# ============================================================
#  JA Saude Animal - Launcher (irm | iex compatible)
#  Download and execute directly with:
#  irm "https://raw.githubusercontent.com/EduardoTi67/JA-S.A-Essentials/main/launcher.ps1" | iex
# ============================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#  PALETA VERDE + BRANCO PREMIUM
# ============================================================

$corFundo        = [System.Drawing.Color]::FromArgb(12,  18,  24)
$corPainel       = [System.Drawing.Color]::FromArgb(20,  28,  38)
$corPainelHov    = [System.Drawing.Color]::FromArgb(28,  40,  52)
$corVerdePrimario = [System.Drawing.Color]::FromArgb(34, 197, 94)
$corVerdeHover    = [System.Drawing.Color]::FromArgb(22, 163, 74)
$corVerdeLeve     = [System.Drawing.Color]::FromArgb(86, 180, 125)
$corBrancoTexto   = [System.Drawing.Color]::FromArgb(255, 255, 255)
$corCinzaTexto    = [System.Drawing.Color]::FromArgb(200, 210, 220)
$corTextoMedio    = [System.Drawing.Color]::FromArgb(170, 180, 200)
$corTextoEscuro   = [System.Drawing.Color]::FromArgb(130, 140, 160)
$corSidebar       = [System.Drawing.Color]::FromArgb(10,  16,  22)
$corSidebarHov    = [System.Drawing.Color]::FromArgb(28,  50,  40)
$corSidebarSel    = [System.Drawing.Color]::FromArgb(20,  70,  50)

# ============================================================
#  CORE FUNCTIONS
# ============================================================

function Escrever-Log {
    param([string]$Msg, [string]$Tipo = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
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
        Set-Service -Name $Nome -StartupType Disabled -ErrorAction SilentlyContinue
        Escrever-Log "Servico '$Nome' desativado!" "OK"
    } catch { Escrever-Log "Aviso ($Nome): $_" "AVISO" }
}

function Rodar-Async {
    param(
        [ScriptBlock]$Bloco,
        [hashtable]$Vars = @{},
        [ScriptBlock]$AoFinalizar = $null
    )
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions = "ReuseThread"
    $rs.Open()
    foreach ($k in $Vars.Keys) { $rs.SessionStateProxy.SetVariable($k, $Vars[$k]) }
    
    $fnLog = ${function:Escrever-Log}.ToString()
    $fnRegSet = ${function:RegSet}.ToString()
    $fnSvcDis = ${function:Svc-Disable}.ToString()
    $rs.SessionStateProxy.SetVariable("fnLog", $fnLog)
    $rs.SessionStateProxy.SetVariable("fnRegSet", $fnRegSet)
    $rs.SessionStateProxy.SetVariable("fnSvcDis", $fnSvcDis)
    $rs.SessionStateProxy.SetVariable("txtLogRef", $script:txtLog)
    
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
        try { $ps.Dispose() } catch {}
        try { $rs.Close() } catch {}
        try { $rs.Dispose() } catch {}
        $cb = $script:_asyncCallbacks[$myIdx]
        $script:_asyncCallbacks.Remove($myIdx)
        if ($cb) { try { & $cb } catch { Write-Host "Erro callback: $_" } }
    })
    $timer.Start()
}

function Criar-Icone {
    $bmp = New-Object System.Drawing.Bitmap(32, 32)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    
    $brush = New-Object System.Drawing.SolidBrush($corVerdePrimario)
    $g.FillEllipse($brush, 0, 0, 31, 31)
    $brush.Dispose()
    
    $penB = New-Object System.Drawing.Pen($corBrancoTexto, 2)
    $g.DrawEllipse($penB, 1, 1, 30, 30)
    $penB.Dispose()
    
    $penC = New-Object System.Drawing.Pen($corBrancoTexto, 3)
    $penC.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penC.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($penC, 16, 8, 16, 24)
    $g.DrawLine($penC, 8, 16, 24, 16)
    $penC.Dispose()
    
    $g.Dispose()
    $icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
    $bmp.Dispose()
    return $icon
}

# ============================================================
#  APPS
# ============================================================

$appsBasicos = @(
    @{ Nome="Firefox"; Winget="Mozilla.Firefox" }
    @{ Nome="Google Chrome"; Winget="Google.Chrome" }
    @{ Nome="Microsoft Edge"; Winget="Microsoft.Edge" }
    @{ Nome="7-Zip"; Winget="7zip.7zip" }
    @{ Nome="VC Redist x86 2005"; Winget="Microsoft.VCRedist.2005.x86" }
    @{ Nome="VC Redist x64 2005"; Winget="Microsoft.VCRedist.2005.x64" }
    @{ Nome="VC Redist x86 2008"; Winget="Microsoft.VCRedist.2008.x86" }
    @{ Nome="VC Redist x64 2008"; Winget="Microsoft.VCRedist.2008.x64" }
    @{ Nome="VC Redist x86 2010"; Winget="Microsoft.VCRedist.2010.x86" }
    @{ Nome="VC Redist x64 2010"; Winget="Microsoft.VCRedist.2010.x64" }
    @{ Nome="VC Redist x86 2012"; Winget="Microsoft.VCRedist.2012.x86" }
    @{ Nome="VC Redist x64 2012"; Winget="Microsoft.VCRedist.2012.x64" }
    @{ Nome="VC Redist x86 2013"; Winget="Microsoft.VCRedist.2013.x86" }
    @{ Nome="VC Redist x64 2013"; Winget="Microsoft.VCRedist.2013.x64" }
    @{ Nome="VC Redist x86 2015+"; Winget="Microsoft.VCRedist.2015+.x86" }
    @{ Nome="VC Redist x64 2015+"; Winget="Microsoft.VCRedist.2015+.x64" }
    @{ Nome=".NET Desktop Runtime 8 x86"; Winget="Microsoft.DotNet.DesktopRuntime.8.x86" }
    @{ Nome=".NET Desktop Runtime 8 x64"; Winget="Microsoft.DotNet.DesktopRuntime.8.x64" }
    @{ Nome=".NET Desktop Runtime 9"; Winget="Microsoft.DotNet.DesktopRuntime.9" }
    @{ Nome=".NET Desktop Runtime 10"; Winget="Microsoft.DotNet.DesktopRuntime.10" }
    @{ Nome="OneDrive"; Winget="Microsoft.OneDrive" }
    @{ Nome="Zoom"; Winget="Zoom.Zoom" }
    @{ Nome="Microsoft Teams"; Winget="Microsoft.Teams" }
    @{ Nome="TeamViewer 15"; Winget="TeamViewer.TeamViewer" }
)

$appsIndividuais = @(
    @{ Nome="Adobe Acrobat Reader 64-bit"; Winget="Adobe.Acrobat.Reader.64-bit"; Desc="Leitor PDF oficial Adobe (64-bit)" }
    @{ Nome="Office 365 Setup"; Winget="Microsoft.Office"; Desc="Microsoft Office 365 (instalador)" }
    @{ Nome="PDF24 Creator"; Winget="geeksoftwareGmbH.PDF24Creator"; Desc="Criador e editor de PDF gratuito" }
    @{ Nome="CutePDF Writer"; Winget="AcroSoftware.CutePDFWriter"; Desc="Impressora virtual para criar PDFs" }
    @{ Nome="OBS Studio"; Winget="OBSProject.OBSStudio"; Desc="Gravacao e streaming de video" }
    @{ Nome="Java 8 (JRE)"; Winget="Oracle.JavaRuntimeEnvironment"; Desc="Java Runtime Environment 8" }
    @{ Nome="VS Code"; Winget="Microsoft.VisualStudioCode"; Desc="Editor de codigo Microsoft" }
    @{ Nome="VLC"; Winget="VideoLAN.VLC"; Desc="Player de midia universal" }
    @{ Nome="Google Earth Pro"; Winget="Google.EarthPro"; Desc="Explorador de mapas 3D" }
)

# ============================================================
#  FORM
# ============================================================

$script:form = New-Object System.Windows.Forms.Form
$script:form.Text = "JA Saude Animal | Ferramenta de TI"
$script:form.Size = New-Object System.Drawing.Size(1200, 780)
$script:form.StartPosition = "CenterScreen"
$script:form.BackColor = $corFundo
$script:form.ForeColor = $corBrancoTexto
$script:form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:form.MinimumSize = New-Object System.Drawing.Size(960, 660)
$script:form.Icon = Criar-Icone
$script:form.FormBorderStyle = "Sizable"

# Accent bar
$pnlAccent = New-Object System.Windows.Forms.Panel
$pnlAccent.Dock = "Top"
$pnlAccent.Height = 5
$pnlAccent.BackColor = $corVerdePrimario
$script:form.Controls.Add($pnlAccent)

# Header
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock = "Top"
$pnlHeader.Height = 72
$pnlHeader.BackColor = $corSidebar
$pnlHeader.add_Paint({
    param($s, $e)
    $e.Graphics.Clear($corSidebar)
    $pen = New-Object System.Drawing.Pen($corVerdePrimario, 3)
    $e.Graphics.DrawLine($pen, 0, $s.Height - 3, $s.Width, $s.Height - 3)
    $pen.Dispose()
})

$pnlIcon = New-Object System.Windows.Forms.Panel
$pnlIcon.Location = New-Object System.Drawing.Point(18, 26)
$pnlIcon.Size = New-Object System.Drawing.Size(18, 18)
$pnlIcon.BackColor = $corVerdePrimario
$pnlIcon.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $b = New-Object System.Drawing.SolidBrush($corVerdePrimario)
    $e.Graphics.FillEllipse($b, 0, 0, 17, 17)
    $b.Dispose()
    $bw = New-Object System.Drawing.SolidBrush($corBrancoTexto)
    $e.Graphics.FillEllipse($bw, 6, 6, 6, 6)
    $bw.Dispose()
})

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "JA Saude Animal"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $corBrancoTexto
$lblTitle.Location = New-Object System.Drawing.Point(46, 10)
$lblTitle.AutoSize = $true
$lblTitle.BackColor = [System.Drawing.Color]::Transparent

$lblVer = New-Object System.Windows.Forms.Label
$lblVer.Text = "v1.1 Premium • irm | iex Compatible"
$lblVer.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblVer.ForeColor = $corVerdeLeve
$lblVer.Location = New-Object System.Drawing.Point(46, 42)
$lblVer.AutoSize = $true
$lblVer.BackColor = [System.Drawing.Color]::Transparent

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Instalacao e Manutencao de Programas"
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$lblSub.ForeColor = $corTextoMedio
$lblSub.Location = New-Object System.Drawing.Point(400, 28)
$lblSub.AutoSize = $true
$lblSub.BackColor = [System.Drawing.Color]::Transparent

$pnlBadge = New-Object System.Windows.Forms.Panel
$pnlBadge.Size = New-Object System.Drawing.Size(110, 26)
$pnlBadge.Location = New-Object System.Drawing.Point(1070, 23)
$pnlBadge.BackColor = $corVerdePrimario

$pnlHeader.Controls.AddRange(@($pnlIcon, $lblTitle, $lblVer, $lblSub, $pnlBadge))
$script:form.Controls.Add($pnlHeader)

# Main container
$pnlMain = New-Object System.Windows.Forms.Panel
$pnlMain.Location = New-Object System.Drawing.Point(0, 74)
$pnlMain.Size = New-Object System.Drawing.Size(1200, 676)
$pnlMain.Anchor = "Top,Left,Bottom,Right"
$pnlMain.BackColor = $corFundo
$script:form.Controls.Add($pnlMain)

# Sidebar
$pnlSidebar = New-Object System.Windows.Forms.Panel
$pnlSidebar.Location = New-Object System.Drawing.Point(0, 0)
$pnlSidebar.Size = New-Object System.Drawing.Size(210, 676)
$pnlSidebar.Anchor = "Top,Left,Bottom"
$pnlSidebar.BackColor = $corSidebar
$pnlMain.Controls.Add($pnlSidebar)

$pnlLogo = New-Object System.Windows.Forms.Panel
$pnlLogo.Location = New-Object System.Drawing.Point(0, 0)
$pnlLogo.Size = New-Object System.Drawing.Size(210, 92)
$pnlLogo.BackColor = $corSidebar
$pnlLogo.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $pen = New-Object System.Drawing.Pen($corVerdePrimario, 2)
    $e.Graphics.DrawLine($pen, 0, $s.Height - 2, $s.Width, $s.Height - 2)
    $pen.Dispose()
})

$l1 = New-Object System.Windows.Forms.Label
$l1.Text = "JA Saude"; $l1.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$l1.ForeColor = $corBrancoTexto; $l1.Location = New-Object System.Drawing.Point(50, 18)
$l1.AutoSize = $true; $l1.BackColor = [System.Drawing.Color]::Transparent

$l2 = New-Object System.Windows.Forms.Label
$l2.Text = "Animal"; $l2.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$l2.ForeColor = $corVerdePrimario; $l2.Location = New-Object System.Drawing.Point(50, 38)
$l2.AutoSize = $true; $l2.BackColor = [System.Drawing.Color]::Transparent

$pnlLogo.Controls.AddRange(@($l1, $l2))
$pnlSidebar.Controls.Add($pnlLogo)

# Content area
$pnlContent = New-Object System.Windows.Forms.Panel
$pnlContent.Location = New-Object System.Drawing.Point(211, 0)
$pnlContent.Size = New-Object System.Drawing.Size(749, 676)
$pnlContent.Anchor = "Top,Left,Bottom,Right"
$pnlContent.BackColor = $corFundo
$pnlMain.Controls.Add($pnlContent)

# Log panel
$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.Location = New-Object System.Drawing.Point(960, 0)
$pnlLog.Size = New-Object System.Drawing.Size(240, 676)
$pnlLog.Anchor = "Top,Right,Bottom"
$pnlLog.BackColor = $corSidebar
$pnlLog.add_Paint({
    param($s, $e)
    $pen = New-Object System.Drawing.Pen($corVerdePrimario, 2)
    $e.Graphics.DrawLine($pen, 0, 0, 0, $s.Height)
    $pen.Dispose()
})
$pnlMain.Controls.Add($pnlLog)

$pnlLogH = New-Object System.Windows.Forms.Panel
$pnlLogH.Location = New-Object System.Drawing.Point(0, 0)
$pnlLogH.Size = New-Object System.Drawing.Size(240, 44)
$pnlLogH.BackColor = $corSidebar
$pnlLogH.add_Paint({
    param($s, $e)
    $pen = New-Object System.Drawing.Pen($corVerdePrimario, 1)
    $e.Graphics.DrawLine($pen, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $pen.Dispose()
})

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "  ◆ LOG"
$lblLog.Font = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
$lblLog.ForeColor = $corVerdePrimario
$lblLog.Location = New-Object System.Drawing.Point(0, 13)
$lblLog.Size = New-Object System.Drawing.Size(240, 18)
$lblLog.BackColor = [System.Drawing.Color]::Transparent
$pnlLogH.Controls.Add($lblLog)
$pnlLog.Controls.Add($pnlLogH)

# Tabs
$pnlTab = New-Object System.Windows.Forms.Panel
$pnlTab.Dock = "Fill"
$pnlTab.BackColor = $corFundo
$pnlTab.AutoScroll = $true
$pnlContent.Controls.Add($pnlTab)

$pnlHdr = New-Object System.Windows.Forms.Panel
$pnlHdr.Dock = "Top"
$pnlHdr.Height = 64
$pnlHdr.BackColor = $corPainel
$pnlHdr.add_Paint({
    param($s, $e)
    $pen = New-Object System.Drawing.Pen($corVerdePrimario, 1)
    $e.Graphics.DrawLine($pen, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $pen.Dispose()
    $brush = New-Object System.Drawing.SolidBrush($corVerdePrimario)
    $e.Graphics.FillRectangle($brush, 0, 0, 4, $s.Height)
    $brush.Dispose()
})

$lblHdr = New-Object System.Windows.Forms.Label
$lblHdr.Text = "📦 Instalar Programas"
$lblHdr.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$lblHdr.ForeColor = $corBrancoTexto
$lblHdr.Location = New-Object System.Drawing.Point(18, 8)
$lblHdr.AutoSize = $true
$lblHdr.BackColor = [System.Drawing.Color]::Transparent

$script:lblCnt = New-Object System.Windows.Forms.Label
$script:lblCnt.Text = "0 selecionado"
$script:lblCnt.ForeColor = $corTextoMedio
$script:lblCnt.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$script:lblCnt.Location = New-Object System.Drawing.Point(550, 20)
$script:lblCnt.AutoSize = $true
$script:lblCnt.BackColor = [System.Drawing.Color]::Transparent

$pnlHdr.Controls.AddRange(@($lblHdr, $script:lblCnt))
$pnlTab.Controls.Add($pnlHdr)

# Checkbox Basicos
$script:chkBasicos = New-Object System.Windows.Forms.CheckBox
$script:chkBasicos.Text = "  Instalar pacote essencial (24 apps)"
$script:chkBasicos.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:chkBasicos.ForeColor = $corBrancoTexto
$script:chkBasicos.BackColor = [System.Drawing.Color]::Transparent
$script:chkBasicos.Location = New-Object System.Drawing.Point(30, 90)
$script:chkBasicos.Size = New-Object System.Drawing.Size(700, 24)
$script:chkBasicos.Cursor = [System.Windows.Forms.Cursors]::Hand
$script:chkBasicos.add_CheckedChanged({
    $this.ForeColor = if ($this.Checked) { $corVerdePrimario } else { $corBrancoTexto }
    Atualizar-Cnt
})
$pnlTab.Controls.Add($script:chkBasicos)

# Checkboxes Individuais
$script:chksIndividuais = @()
$yPos = 130

function Atualizar-Cnt {
    $t = 0
    if ($script:chkBasicos.Checked) { $t++ }
    foreach ($c in $script:chksIndividuais) { if ($c.Checked) { $t++ } }
    $script:lblCnt.Text = "$t selecionado(s)"
    $script:lblCnt.ForeColor = if ($t -gt 0) { $corVerdePrimario } else { $corTextoMedio }
}

foreach ($app in $appsIndividuais) {
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = "$($app.Nome) - $($app.Desc)"
    $chk.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $chk.ForeColor = $corBrancoTexto
    $chk.BackColor = [System.Drawing.Color]::Transparent
    $chk.Location = New-Object System.Drawing.Point(30, $yPos)
    $chk.AutoSize = $true
    $chk.Cursor = [System.Windows.Forms.Cursors]::Hand
    $chk.add_CheckedChanged({
        $this.ForeColor = if ($this.Checked) { $corVerdePrimario } else { $corBrancoTexto }
        Atualizar-Cnt
    })
    $pnlTab.Controls.Add($chk)
    $script:chksIndividuais += $chk
    $yPos += 30
}

# Button Instalar
$btnInst = New-Object System.Windows.Forms.Button
$btnInst.Text = "▶ INSTALAR SELECIONADOS"
$btnInst.Location = New-Object System.Drawing.Point(30, ($yPos + 20))
$btnInst.Size = New-Object System.Drawing.Size(300, 50)
$btnInst.BackColor = $corVerdePrimario
$btnInst.ForeColor = $corBrancoTexto
$btnInst.FlatStyle = "Flat"
$btnInst.FlatAppearance.BorderSize = 0
$btnInst.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnInst.Cursor = [System.Windows.Forms.Cursors]::Hand
$script:btnInst = $btnInst

$btnInst.add_Click({
    $lista = @()
    if ($script:chkBasicos.Checked) { $lista += $appsBasicos }
    for ($i = 0; $i -lt $script:chksIndividuais.Count; $i++) {
        if ($script:chksIndividuais[$i].Checked) { $lista += $appsIndividuais[$i] }
    }
    
    if ($lista.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Selecione ao menos um item","Atencao","OK","Warning") | Out-Null
        return
    }

    $script:btnInst.Enabled = $false
    $total = $lista.Count
    $script:btnInst.Text = "Instalando... (0/$total)"

    Rodar-Async -Vars @{lista=$lista; total=$total} -Bloco {
        $n = 0
        foreach ($app in $lista) {
            $n++
            Escrever-Log "[$n/$total] $($app.Nome)..."
            & winget install --id $app.Winget --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
                Escrever-Log "$($app.Nome) OK!" "OK"
            } else {
                Escrever-Log "$($app.Nome) pode ja estar instalado" "INFO"
            }
        }
        Escrever-Log "Concluido!" "OK"
    } -AoFinalizar {
        $script:btnInst.Enabled = $true
        $script:btnInst.Text = "▶ INSTALAR SELECIONADOS"
    }
})
$pnlTab.Controls.Add($btnInst)

# Log TextBox
$script:txtLog = New-Object System.Windows.Forms.RichTextBox
$script:txtLog.Location = New-Object System.Drawing.Point(8, 48)
$script:txtLog.Size = New-Object System.Drawing.Size(224, 614)
$script:txtLog.Anchor = "Top,Left,Bottom,Right"
$script:txtLog.BackColor = $corFundo
$script:txtLog.ForeColor = $corVerdePrimario
$script:txtLog.Font = New-Object System.Drawing.Font("Consolas", 7)
$script:txtLog.ReadOnly = $true
$script:txtLog.BorderStyle = "None"
$pnlLog.Controls.Add($script:txtLog)

Escrever-Log "JA Saude Animal iniciado!"
Escrever-Log "Pronto para instalar"

# Show
$script:form.Add_Shown({ $script:form.Activate() })
$script:form.ShowDialog() | Out-Null
