# ============================================================
#  JA Saude Animal - Ferramenta de TI
#  by JA Saude Animal
#  v1.0 - Instalacao de Programas + Ferramentas de Sistema
# ============================================================
 
#Requires -RunAsAdministrator
 
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
 
# ============================================================
#  PALETA PREMIUM 2026 - Dark Emerald
#  Fundo escuro profundo + verde esmeralda + dourado
# ============================================================
 
# --- Fundos ---
$corFundo        = [System.Drawing.Color]::FromArgb(10,  14,  20)   # quase preto azulado
$corPainel       = [System.Drawing.Color]::FromArgb(16,  22,  30)   # card escuro
$corPainelHov    = [System.Drawing.Color]::FromArgb(22,  30,  40)   # card hover
$corPainelAlt    = [System.Drawing.Color]::FromArgb(13,  18,  25)   # alt background
 
# --- Bordas e separadores ---
$corBorda        = [System.Drawing.Color]::FromArgb(30,  45,  35)
$corBordaSutil   = [System.Drawing.Color]::FromArgb(22,  34,  28)
$corBordaBrilho  = [System.Drawing.Color]::FromArgb(46, 139, 87)
 
# --- Verdes (marca) ---
$corDestaque     = [System.Drawing.Color]::FromArgb(52, 211, 153)   # emerald-400 vibrante
$corDestaqueHov  = [System.Drawing.Color]::FromArgb(16, 185, 129)   # emerald-500
$corDestaqueDark = [System.Drawing.Color]::FromArgb(6,  95,  70)    # emerald deep
$corVerde        = [System.Drawing.Color]::FromArgb(52, 211, 153)
$corVerdeDim     = [System.Drawing.Color]::FromArgb(20, 80,  55)    # verde escurecido p/ backgrounds
$corVerdeGlow    = [System.Drawing.Color]::FromArgb(31, 120, 90)
 
# --- Amarelo/dourado (acento) ---
$corAmarelo      = [System.Drawing.Color]::FromArgb(251, 191, 36)   # amber-400
$corAmareloHov   = [System.Drawing.Color]::FromArgb(245, 158, 11)   # amber-500
$corAmareloDim   = [System.Drawing.Color]::FromArgb(78,  60,  10)   # amber background
 
# --- Alerta / Perigo ---
$corVermelho     = [System.Drawing.Color]::FromArgb(248,  81,  73)
$corVermelhoDim  = [System.Drawing.Color]::FromArgb(80,  20,  20)
 
# --- Textos ---
$corTexto        = [System.Drawing.Color]::FromArgb(226, 232, 240)  # slate-200 (texto principal)
$corTextoClaro   = [System.Drawing.Color]::FromArgb(255, 255, 255)
$corTextoEscuro  = [System.Drawing.Color]::FromArgb(100, 116, 139)  # slate-500
$corTextoMedio   = [System.Drawing.Color]::FromArgb(148, 163, 184)  # slate-400
 
# --- Sidebar ---
$corSidebar      = [System.Drawing.Color]::FromArgb(8,   12,  17)   # sidebar quase preta
$corSidebarText  = [System.Drawing.Color]::FromArgb(148, 163, 184)
$corSidebarHov   = [System.Drawing.Color]::FromArgb(20,  30,  22)
$corSidebarSel   = [System.Drawing.Color]::FromArgb(14,  50,  36)   # selecionado: verde escuro
 
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
    $bmp = New-Object System.Drawing.Bitmap(32, 32)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode    = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.CompositingMode  = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $g.Clear([System.Drawing.Color]::Transparent)
 
    # Fundo circular com gradiente esmeralda
    $gradFundo = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0,0)),
        (New-Object System.Drawing.PointF(32,32)),
        [System.Drawing.Color]::FromArgb(52, 211, 153),
        [System.Drawing.Color]::FromArgb(6, 95, 70)
    )
    $g.FillEllipse($gradFundo, 0, 0, 31, 31)
    $gradFundo.Dispose()
 
    # Cruz branca simples (medica)
    $penBranco = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 3)
    $penBranco.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penBranco.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($penBranco, 16, 8, 16, 24)
    $g.DrawLine($penBranco, 8, 16, 24, 16)
    $penBranco.Dispose()
 
    $g.Dispose()
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
    @{ Nome=".NET Desktop Runtime 9"; Winget="Microsoft.DotNet.DesktopRuntime.9" }
    @{ Nome=".NET Desktop Runtime 10";Winget="Microsoft.DotNet.DesktopRuntime.10" }
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
    @{ Nome="Office 365 Setup";            Winget="Microsoft.Office";              Desc="Microsoft Office 365 (instalador)" }
    @{ Nome="PDF24 Creator";               Winget="geeksoftwareGmbH.PDF24Creator";  Desc="Criador e editor de PDF gratuito" }
    @{ Nome="CutePDF Writer";              Winget="AcroSoftware.CutePDFWriter";          Desc="Impressora virtual para criar PDFs" }
    @{ Nome="OBS Studio";                  Winget="OBSProject.OBSStudio";           Desc="Gravacao e streaming de video" }
    @{ Nome="Java 8 (JRE)";               Winget="Oracle.JavaRuntimeEnvironment";  Desc="Java Runtime Environment 8" }
    @{ Nome="VS Code";                     Winget="Microsoft.VisualStudioCode";     Desc="Editor de codigo Microsoft" }
    @{ Nome="VLC";                         Winget="VideoLAN.VLC";                   Desc="Player de midia universal" }
    @{ Nome="Google Earth Pro";            Winget="Google.EarthPro";          Desc="Explorador de mapas 3D" }
)
 
# =================================================================
#  JANELA PRINCIPAL - REDESIGN PREMIUM 2026
# =================================================================
$script:form = New-Object System.Windows.Forms.Form
$script:form.Text          = "JA Saude Animal  |  Ferramenta de TI"
$script:form.Size          = New-Object System.Drawing.Size(1200, 780)
$script:form.StartPosition = "CenterScreen"
$script:form.BackColor     = $corFundo
$script:form.ForeColor     = $corTexto
$script:form.Font          = New-Object System.Drawing.Font("Segoe UI", 9)
$script:form.MinimumSize   = New-Object System.Drawing.Size(960, 660)
$script:form.Icon          = Criar-Icone
$script:form.FormBorderStyle = "Sizable"
 
# --- Barra de acento topo (gradiente verde-azul esmeralda) ---
$pnlAccent = New-Object System.Windows.Forms.Panel
$pnlAccent.Dock      = "Top"
$pnlAccent.Height    = 3
$pnlAccent.BackColor = $corDestaque
$script:form.Controls.Add($pnlAccent)
 
# --- Header premium ---
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock      = "Top"
$pnlHeader.Height    = 68
$pnlHeader.BackColor = $corSidebar
 
# Paint handler para gradiente no header
$pnlHeader.add_Paint({
    param($s, $e)
    $rect  = New-Object System.Drawing.Rectangle(0, 0, $s.Width, $s.Height)
    $grad  = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF($s.Width, 0)),
        [System.Drawing.Color]::FromArgb(8, 12, 17),
        [System.Drawing.Color]::FromArgb(14, 22, 18)
    )
    $e.Graphics.FillRectangle($grad, $rect)
    $grad.Dispose()
    # Linha inferior esmeralda
    $penLine = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(52, 211, 153), 1)
    $e.Graphics.DrawLine($penLine, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $penLine.Dispose()
})
 
# Icone decorativo (bolinha verde pulsante - simulada com panel)
$pnlDot = New-Object System.Windows.Forms.Panel
$pnlDot.Location  = New-Object System.Drawing.Point(18, 24)
$pnlDot.Size      = New-Object System.Drawing.Size(20, 20)
$pnlDot.BackColor = $corDestaque
$pnlDot.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(52, 211, 153))
    $e.Graphics.FillEllipse($brush, 0, 0, 19, 19)
    $brush.Dispose()
    # Brilho interno
    $brushGlow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 255, 255, 255))
    $e.Graphics.FillEllipse($brushGlow, 4, 3, 7, 6)
    $brushGlow.Dispose()
})
 
$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text      = "JA Saude Animal"
$lblTitulo.Font      = New-Object System.Drawing.Font("Segoe UI Semibold", 20, [System.Drawing.FontStyle]::Bold)
$lblTitulo.ForeColor = $corTextoClaro
$lblTitulo.Location  = New-Object System.Drawing.Point(46, 8)
$lblTitulo.AutoSize  = $true
$lblTitulo.BackColor = [System.Drawing.Color]::Transparent
 
$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text      = "v1.0"
$lblVersion.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$lblVersion.ForeColor = $corDestaque
$lblVersion.Location  = New-Object System.Drawing.Point(46, 40)
$lblVersion.AutoSize  = $true
$lblVersion.BackColor = [System.Drawing.Color]::Transparent
 
# Separator vertical
$sepHeaderV = New-Object System.Windows.Forms.Panel
$sepHeaderV.Location  = New-Object System.Drawing.Point(268, 16)
$sepHeaderV.Size      = New-Object System.Drawing.Size(1, 36)
$sepHeaderV.BackColor = [System.Drawing.Color]::FromArgb(40, 60, 50)
 
$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text      = "Ferramenta de TI  |  Instalacao e Manutencao"
$lblSub.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
$lblSub.ForeColor = $corTextoMedio
$lblSub.Location  = New-Object System.Drawing.Point(280, 14)
$lblSub.AutoSize  = $true
$lblSub.BackColor = [System.Drawing.Color]::Transparent
 
# Badge "ADMIN" no canto direito do header
$pnlBadge = New-Object System.Windows.Forms.Panel
$pnlBadge.Size      = New-Object System.Drawing.Size(80, 22)
$pnlBadge.BackColor = $corVerdeDim
$pnlBadge.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $brush = New-Object System.Drawing.SolidBrush($corVerdeDim)
    $e.Graphics.FillRectangle($brush, 0, 0, $s.Width, $s.Height)
    $brush.Dispose()
    $penBord = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(52, 211, 153), 1)
    $e.Graphics.DrawRectangle($penBord, 0, 0, $s.Width - 1, $s.Height - 1)
    $penBord.Dispose()
    $lblF = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
    $sf   = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $e.Graphics.DrawString("ADMINISTRADOR", $lblF, (New-Object System.Drawing.SolidBrush($corDestaque)), (New-Object System.Drawing.RectangleF(0, 0, $s.Width, $s.Height)), $sf)
    $lblF.Dispose()
    $sf.Dispose()
})
$pnlBadge.Location = New-Object System.Drawing.Point(900, 23)
 
$pnlHeader.Controls.AddRange(@($pnlDot, $lblTitulo, $lblVersion, $sepHeaderV, $lblSub, $pnlBadge))
$script:form.Controls.Add($pnlHeader)
 
# --- Container principal ---
$pnlMain = New-Object System.Windows.Forms.Panel
$pnlMain.Location  = New-Object System.Drawing.Point(0, 74)
$pnlMain.Size      = New-Object System.Drawing.Size(1200, 676)
$pnlMain.Anchor    = "Top,Left,Bottom,Right"
$pnlMain.BackColor = $corFundo
$script:form.Controls.Add($pnlMain)
 
# =================================================================
#  SIDEBAR PREMIUM
# =================================================================
$pnlSidebar = New-Object System.Windows.Forms.Panel
$pnlSidebar.Location  = New-Object System.Drawing.Point(0, 0)
$pnlSidebar.Size      = New-Object System.Drawing.Size(210, 676)
$pnlSidebar.Anchor    = "Top,Left,Bottom"
$pnlSidebar.BackColor = $corSidebar
 
# Paint handler para sidebar com gradiente sutil
$pnlSidebar.add_Paint({
    param($s, $e)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $s.Width, $s.Height)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF($s.Width, 0)),
        [System.Drawing.Color]::FromArgb(8, 12, 17),
        [System.Drawing.Color]::FromArgb(11, 16, 20)
    )
    $e.Graphics.FillRectangle($grad, $rect)
    $grad.Dispose()
    # Linha direita de separação
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 34, 28), 1)
    $e.Graphics.DrawLine($pen, $s.Width - 1, 0, $s.Width - 1, $s.Height)
    $pen.Dispose()
})
 
$pnlMain.Controls.Add($pnlSidebar)
 
# Logo / avatar na sidebar
$pnlSidelogo = New-Object System.Windows.Forms.Panel
$pnlSidelogo.Location  = New-Object System.Drawing.Point(0, 0)
$pnlSidelogo.Size      = New-Object System.Drawing.Size(210, 80)
$pnlSidelogo.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 12)
$pnlSidelogo.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    # Fundo sutil
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(10, 16, 12))
    $e.Graphics.FillRectangle($brush, 0, 0, $s.Width, $s.Height)
    $brush.Dispose()
    # Cruz médica centralizada
    $penCruz = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(52, 211, 153), 4)
    $penCruz.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penCruz.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $e.Graphics.DrawLine($penCruz, 24, 40, 24, 60)
    $e.Graphics.DrawLine($penCruz, 14, 50, 34, 50)
    $penCruz.Dispose()
    # Circulo ao redor
    $penCirc = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(52, 211, 153), 2)
    $e.Graphics.DrawEllipse($penCirc, 8, 26, 32, 32)
    $penCirc.Dispose()
    # Texto
    $fnt  = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $fnt2 = New-Object System.Drawing.Font("Segoe UI", 7)
    $e.Graphics.DrawString("JA Saude", $fnt, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(226,232,240))), 50, 22)
    $e.Graphics.DrawString("Animal", $fnt, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(52,211,153))), 50, 42)
    $e.Graphics.DrawString("Ferramenta de TI v1.0", $fnt2, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100,116,139))), 50, 62)
    $fnt.Dispose(); $fnt2.Dispose()
    # Linha inferior
    $penSep = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 34, 28), 1)
    $e.Graphics.DrawLine($penSep, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $penSep.Dispose()
})
$pnlSidebar.Controls.Add($pnlSidelogo)
 
# Separador de secao na sidebar
$pnlNavLabel = New-Object System.Windows.Forms.Panel
$pnlNavLabel.Location  = New-Object System.Drawing.Point(0, 80)
$pnlNavLabel.Size      = New-Object System.Drawing.Size(210, 28)
$pnlNavLabel.BackColor = [System.Drawing.Color]::FromArgb(8, 12, 17)
$lblNavSec = New-Object System.Windows.Forms.Label
$lblNavSec.Text      = "  NAVEGACAO"
$lblNavSec.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
$lblNavSec.ForeColor = [System.Drawing.Color]::FromArgb(52, 71, 63)
$lblNavSec.Location  = New-Object System.Drawing.Point(10, 8)
$lblNavSec.AutoSize  = $true
$pnlNavLabel.Controls.Add($lblNavSec)
$pnlSidebar.Controls.Add($pnlNavLabel)
 
# --- Area de conteudo ---
$pnlContent = New-Object System.Windows.Forms.Panel
$pnlContent.Location  = New-Object System.Drawing.Point(211, 0)
$pnlContent.Size      = New-Object System.Drawing.Size(749, 676)
$pnlContent.Anchor    = "Top,Left,Bottom,Right"
$pnlContent.BackColor = $corFundo
$pnlMain.Controls.Add($pnlContent)
 
# --- LOG panel ---
$pnlLogOuter = New-Object System.Windows.Forms.Panel
$pnlLogOuter.Location  = New-Object System.Drawing.Point(960, 0)
$pnlLogOuter.Size      = New-Object System.Drawing.Size(240, 676)
$pnlLogOuter.Anchor    = "Top,Right,Bottom"
$pnlLogOuter.BackColor = $corSidebar
$pnlLogOuter.add_Paint({
    param($s, $e)
    # Borda esquerda verde sutil
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 34, 28), 1)
    $e.Graphics.DrawLine($pen, 0, 0, 0, $s.Height)
    $pen.Dispose()
})
$pnlMain.Controls.Add($pnlLogOuter)
 
# Header do Log
$pnlLogHeader = New-Object System.Windows.Forms.Panel
$pnlLogHeader.Location  = New-Object System.Drawing.Point(0, 0)
$pnlLogHeader.Size      = New-Object System.Drawing.Size(240, 36)
$pnlLogHeader.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 12)
$pnlLogHeader.add_Paint({
    param($s, $e)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 34, 28), 1)
    $e.Graphics.DrawLine($pen, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $pen.Dispose()
    # Ponto verde
    $br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(52, 211, 153))
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $e.Graphics.FillEllipse($br, 12, 13, 8, 8)
    $br.Dispose()
})
$lblLogTitH = New-Object System.Windows.Forms.Label
$lblLogTitH.Text      = "     LOG DE ATIVIDADES"
$lblLogTitH.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
$lblLogTitH.ForeColor = $corTextoMedio
$lblLogTitH.Location  = New-Object System.Drawing.Point(0, 10)
$lblLogTitH.Size      = New-Object System.Drawing.Size(240, 18)
$lblLogTitH.BackColor = [System.Drawing.Color]::Transparent
$pnlLogHeader.Controls.Add($lblLogTitH)
$pnlLogOuter.Controls.Add($pnlLogHeader)
 
# Referencia para o pnlLog (compatibilidade com código existente)
$pnlLog = $pnlLogOuter
 
# =================================================================
#  TABS - SIDEBAR BUTTONS REDESIGN PREMIUM
# =================================================================
$tabDefs = @(
    @{ Label="Instalar Programas"; Icon="+" }
    @{ Label="Sistema";            Icon="S" }
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
            $tabButtons[$i].ForeColor = $corDestaque
        } else {
            $tabButtons[$i].BackColor = $corSidebar
            $tabButtons[$i].ForeColor = $corSidebarText
        }
        $tabButtons[$i].Refresh()
    }
}
 
$yBtn = 110
foreach ($def in $tabDefs) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = "   $($def.Icon)   $($def.Label)"
    $btn.Location  = New-Object System.Drawing.Point(0, $yBtn)
    $btn.Size      = New-Object System.Drawing.Size(210, 48)
    $btn.BackColor = $corSidebar
    $btn.ForeColor = $corSidebarText
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize            = 0
    $btn.FlatAppearance.MouseOverBackColor    = $corSidebarHov
    $btn.FlatAppearance.CheckedBackColor      = $corSidebarSel
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
$sepSideLine.Location  = New-Object System.Drawing.Point(20, ($yBtn + 6))
$sepSideLine.Size      = New-Object System.Drawing.Size(170, 1)
$sepSideLine.BackColor = [System.Drawing.Color]::FromArgb(22, 34, 28)
$pnlSidebar.Controls.Add($sepSideLine)
 
# Status do sistema na parte inferior da sidebar
$pnlSideStatus = New-Object System.Windows.Forms.Panel
$pnlSideStatus.Location  = New-Object System.Drawing.Point(0, 590)
$pnlSideStatus.Size      = New-Object System.Drawing.Size(210, 86)
$pnlSideStatus.BackColor = [System.Drawing.Color]::FromArgb(8, 12, 17)
$pnlSideStatus.Anchor    = "Bottom,Left"
$pnlSideStatus.add_Paint({
    param($s, $e)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 34, 28), 1)
    $e.Graphics.DrawLine($pen, 0, 0, $s.Width, 0)
    $pen.Dispose()
})
 
$lblSideUser = New-Object System.Windows.Forms.Label
$lblSideUser.Text      = "Usuario: $env:USERNAME"
$lblSideUser.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
$lblSideUser.ForeColor = $corTextoMedio
$lblSideUser.Location  = New-Object System.Drawing.Point(12, 12)
$lblSideUser.Size      = New-Object System.Drawing.Size(186, 16)
$lblSideUser.BackColor = [System.Drawing.Color]::Transparent
 
$lblSideMaq = New-Object System.Windows.Forms.Label
$lblSideMaq.Text      = "Maquina: $env:COMPUTERNAME"
$lblSideMaq.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
$lblSideMaq.ForeColor = $corTextoMedio
$lblSideMaq.Location  = New-Object System.Drawing.Point(12, 30)
$lblSideMaq.Size      = New-Object System.Drawing.Size(186, 16)
$lblSideMaq.BackColor = [System.Drawing.Color]::Transparent
 
$lblSideCopy = New-Object System.Windows.Forms.Label
$lblSideCopy.Text      = "JA Saude Animal - TI"
$lblSideCopy.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
$lblSideCopy.ForeColor = $corVerdeDim
$lblSideCopy.Location  = New-Object System.Drawing.Point(12, 60)
$lblSideCopy.AutoSize  = $true
$lblSideCopy.BackColor = [System.Drawing.Color]::Transparent
 
$pnlSideStatus.Controls.AddRange(@($lblSideUser, $lblSideMaq, $lblSideCopy))
$pnlSidebar.Controls.Add($pnlSideStatus)
 
# =================================================================
#  ABA 0 - INSTALAR PROGRAMAS - REDESIGN PREMIUM
# =================================================================
$pInst = $tabPanels[0]
 
$pnlInstScroll = New-Object System.Windows.Forms.Panel
$pnlInstScroll.Dock       = "Fill"
$pnlInstScroll.BackColor  = $corFundo
$pnlInstScroll.AutoScroll = $true
 
# --- Page Header ---
$pnlPageHdr = New-Object System.Windows.Forms.Panel
$pnlPageHdr.Dock      = "Top"
$pnlPageHdr.Height    = 60
$pnlPageHdr.BackColor = $corPainelAlt
$pnlPageHdr.add_Paint({
    param($s, $e)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 34, 28), 1)
    $e.Graphics.DrawLine($pen, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $pen.Dispose()
    # Acento verde esquerda
    $br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(52, 211, 153))
    $e.Graphics.FillRectangle($br, 0, 0, 3, $s.Height)
    $br.Dispose()
})
 
$lblPageTit = New-Object System.Windows.Forms.Label
$lblPageTit.Text      = "Instalar Programas"
$lblPageTit.Font      = New-Object System.Drawing.Font("Segoe UI Semibold", 14, [System.Drawing.FontStyle]::Bold)
$lblPageTit.ForeColor = $corTextoClaro
$lblPageTit.Location  = New-Object System.Drawing.Point(18, 10)
$lblPageTit.AutoSize  = $true
$lblPageTit.BackColor = [System.Drawing.Color]::Transparent
 
$lblPageSub = New-Object System.Windows.Forms.Label
$lblPageSub.Text      = "Selecione os pacotes desejados e clique em Instalar"
$lblPageSub.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblPageSub.ForeColor = $corTextoMedio
$lblPageSub.Location  = New-Object System.Drawing.Point(18, 36)
$lblPageSub.AutoSize  = $true
$lblPageSub.BackColor = [System.Drawing.Color]::Transparent
 
# CONTADOR no header
$script:lblContadorInst = New-Object System.Windows.Forms.Label
$script:lblContadorInst.Text      = "0 selecionado(s)"
$script:lblContadorInst.ForeColor = $corTextoMedio
$script:lblContadorInst.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$script:lblContadorInst.Location  = New-Object System.Drawing.Point(560, 20)
$script:lblContadorInst.AutoSize  = $true
$script:lblContadorInst.BackColor = [System.Drawing.Color]::Transparent
 
$btnLimparInst = New-Object System.Windows.Forms.Button
$btnLimparInst.Text      = "Limpar"
$btnLimparInst.Location  = New-Object System.Drawing.Point(660, 14)
$btnLimparInst.Size      = New-Object System.Drawing.Size(80, 30)
$btnLimparInst.BackColor = [System.Drawing.Color]::FromArgb(22, 34, 28)
$btnLimparInst.ForeColor = $corTextoMedio
$btnLimparInst.FlatStyle = "Flat"
$btnLimparInst.FlatAppearance.BorderSize = 1
$btnLimparInst.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(30, 45, 35)
$btnLimparInst.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$btnLimparInst.Cursor    = [System.Windows.Forms.Cursors]::Hand
 
$pnlPageHdr.Controls.AddRange(@($lblPageTit, $lblPageSub, $script:lblContadorInst, $btnLimparInst))
 
function Atualizar-ContadorInst {
    $total = 0
    if ($script:chkBasicos -and $script:chkBasicos.Checked) { $total++ }
    foreach ($chk in $script:chksIndividuais) {
        if ($chk.Checked) { $total++ }
    }
    $script:lblContadorInst.Text      = "$total selecionado(s)"
    $script:lblContadorInst.ForeColor = if ($total -gt 0) { $corDestaque } else { $corTextoMedio }
}
 
# -------------------------------------------------------
#  BLOCO: PACOTE BASICO - CARD PREMIUM
# -------------------------------------------------------
$yScroll = 14
 
$pnlBlocoBasico = New-Object System.Windows.Forms.Panel
$pnlBlocoBasico.Location  = New-Object System.Drawing.Point(14, $yScroll)
$pnlBlocoBasico.Size      = New-Object System.Drawing.Size(706, 0)
$pnlBlocoBasico.BackColor = $corPainel
$pnlBlocoBasico.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    # Borda sutil ao redor do card
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 34, 28), 1)
    $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1)
    $pen.Dispose()
    # Acento lateral verde degradê
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(0, $s.Height)),
        [System.Drawing.Color]::FromArgb(52, 211, 153),
        [System.Drawing.Color]::FromArgb(6, 95, 70)
    )
    $e.Graphics.FillRectangle($grad, 0, 0, 3, $s.Height)
    $grad.Dispose()
})
 
# Icone + titulo do bloco
$pnlBlocoHdr = New-Object System.Windows.Forms.Panel
$pnlBlocoHdr.Location  = New-Object System.Drawing.Point(3, 0)
$pnlBlocoHdr.Size      = New-Object System.Drawing.Size(700, 52)
$pnlBlocoHdr.BackColor = [System.Drawing.Color]::FromArgb(14, 20, 16)
 
$lblBasicoTit = New-Object System.Windows.Forms.Label
$lblBasicoTit.Text      = "  Pacote Completo - Apps Essenciais"
$lblBasicoTit.Font      = New-Object System.Drawing.Font("Segoe UI Semibold", 12, [System.Drawing.FontStyle]::Bold)
$lblBasicoTit.ForeColor = $corDestaque
$lblBasicoTit.Location  = New-Object System.Drawing.Point(10, 8)
$lblBasicoTit.AutoSize  = $true
$lblBasicoTit.BackColor = [System.Drawing.Color]::Transparent
 
$lblBasicoCount = New-Object System.Windows.Forms.Label
$lblBasicoCount.Text      = "24 itens inclusos"
$lblBasicoCount.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblBasicoCount.ForeColor = $corTextoMedio
$lblBasicoCount.Location  = New-Object System.Drawing.Point(12, 32)
$lblBasicoCount.AutoSize  = $true
$lblBasicoCount.BackColor = [System.Drawing.Color]::Transparent
 
$pnlBlocoHdr.Controls.AddRange(@($lblBasicoTit, $lblBasicoCount))
$pnlBlocoBasico.Controls.Add($pnlBlocoHdr)
 
# Tags visuais dos apps inclusos
$tagApps = @("Firefox","Chrome","Edge","7-Zip","VC Redist x86/x64","NET Runtime 8/9/10","OneDrive","Zoom","Teams","TeamViewer")
$xTag = 16; $yTag = 62
foreach ($tag in $tagApps) {
    $pnlTag = New-Object System.Windows.Forms.Panel
    $txtLen = ($tag.Length * 7) + 20
    $pnlTag.Size      = New-Object System.Drawing.Size($txtLen, 22)
    $pnlTag.BackColor = $corVerdeDim
    $pnlTag.add_Paint({
        param($s, $e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddRectangle(0, 0, $s.Width - 1, $s.Height - 1)
        $e.Graphics.FillPath((New-Object System.Drawing.SolidBrush($s.BackColor)), $path)
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(31, 120, 90), 1)
        $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1)
        $pen.Dispose()
        $path.Dispose()
    })
    $lblTag = New-Object System.Windows.Forms.Label
    $lblTag.Text      = $tag
    $lblTag.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
    $lblTag.ForeColor = $corDestaque
    $lblTag.Location  = New-Object System.Drawing.Point(8, 4)
    $lblTag.AutoSize  = $true
    $lblTag.BackColor = [System.Drawing.Color]::Transparent
    $pnlTag.Controls.Add($lblTag)
 
    if (($xTag + $txtLen + 8) -gt 680) { $xTag = 16; $yTag += 28 }
    $pnlTag.Location = New-Object System.Drawing.Point($xTag, $yTag)
    $xTag += $txtLen + 8
    $pnlBlocoBasico.Controls.Add($pnlTag)
}
 
# Separador
$sepBloco = New-Object System.Windows.Forms.Panel
$sepBloco.Location  = New-Object System.Drawing.Point(16, ($yTag + 30))
$sepBloco.Size      = New-Object System.Drawing.Size(674, 1)
$sepBloco.BackColor = [System.Drawing.Color]::FromArgb(22, 34, 28)
$pnlBlocoBasico.Controls.Add($sepBloco)
 
# Checkbox principal - estilizado
$script:chkBasicos = New-Object System.Windows.Forms.CheckBox
$script:chkBasicos.Text      = "   Instalar todos os apps essenciais acima"
$script:chkBasicos.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:chkBasicos.ForeColor = $corTextoClaro
$script:chkBasicos.BackColor = [System.Drawing.Color]::Transparent
$script:chkBasicos.Location  = New-Object System.Drawing.Point(16, ($yTag + 40))
$script:chkBasicos.Size      = New-Object System.Drawing.Size(660, 28)
$script:chkBasicos.Cursor    = [System.Windows.Forms.Cursors]::Hand
$script:chkBasicos.add_CheckedChanged({
    Atualizar-ContadorInst
    if ($script:chkBasicos.Checked) {
        $script:chkBasicos.ForeColor = $corDestaque
    } else {
        $script:chkBasicos.ForeColor = $corTextoClaro
    }
})
$pnlBlocoBasico.Controls.Add($script:chkBasicos)
 
$alturaBloco1 = 52 + ($yTag - 62) + 28 + 28 + 16 + 18
$pnlBlocoBasico.Height = $alturaBloco1
$pnlInstScroll.Controls.Add($pnlBlocoBasico)
 
# -------------------------------------------------------
#  BLOCO: APPS INDIVIDUAIS - CARDS PREMIUM
# -------------------------------------------------------
$yScroll2 = $yScroll + $alturaBloco1 + 16
 
$pnlBlocoIndiv = New-Object System.Windows.Forms.Panel
$pnlBlocoIndiv.Location  = New-Object System.Drawing.Point(14, $yScroll2)
$pnlBlocoIndiv.BackColor = $corPainel
$pnlBlocoIndiv.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 34, 28), 1)
    $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1)
    $pen.Dispose()
    # Acento lateral amarelo/dourado
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(0, $s.Height)),
        [System.Drawing.Color]::FromArgb(251, 191, 36),
        [System.Drawing.Color]::FromArgb(78, 60, 10)
    )
    $e.Graphics.FillRectangle($grad, 0, 0, 3, $s.Height)
    $grad.Dispose()
})
 
$pnlIndivHdr = New-Object System.Windows.Forms.Panel
$pnlIndivHdr.Location  = New-Object System.Drawing.Point(3, 0)
$pnlIndivHdr.Size      = New-Object System.Drawing.Size(700, 46)
$pnlIndivHdr.BackColor = [System.Drawing.Color]::FromArgb(20, 16, 8)
 
$lblIndivTit = New-Object System.Windows.Forms.Label
$lblIndivTit.Text      = "  Aplicativos Adicionais"
$lblIndivTit.Font      = New-Object System.Drawing.Font("Segoe UI Semibold", 12, [System.Drawing.FontStyle]::Bold)
$lblIndivTit.ForeColor = $corAmarelo
$lblIndivTit.Location  = New-Object System.Drawing.Point(10, 8)
$lblIndivTit.AutoSize  = $true
$lblIndivTit.BackColor = [System.Drawing.Color]::Transparent
 
$lblIndivSub = New-Object System.Windows.Forms.Label
$lblIndivSub.Text      = "Selecione individualmente"
$lblIndivSub.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblIndivSub.ForeColor = $corTextoMedio
$lblIndivSub.Location  = New-Object System.Drawing.Point(12, 30)
$lblIndivSub.AutoSize  = $true
$lblIndivSub.BackColor = [System.Drawing.Color]::Transparent
 
$pnlIndivHdr.Controls.AddRange(@($lblIndivTit, $lblIndivSub))
$pnlBlocoIndiv.Controls.Add($pnlIndivHdr)
 
# Checkboxes individuais - estilo linha de tabela premium
$script:chksIndividuais = @()
$yChk = 46
 
foreach ($app in $appsIndividuais) {
    $pnlApp = New-Object System.Windows.Forms.Panel
    $pnlApp.Location  = New-Object System.Drawing.Point(3, $yChk)
    $pnlApp.Size      = New-Object System.Drawing.Size(700, 42)
    $pnlApp.BackColor = $corPainel
    $pnlApp.Tag       = $false  # hover state
 
    # Hover effect
    $pnlApp.add_MouseEnter({
        param($s,$e)
        if (-not ($s.Controls | Where-Object {$_ -is [System.Windows.Forms.CheckBox] -and $_.Checked})) {
            $s.BackColor = $corPainelHov
        }
    })
    $pnlApp.add_MouseLeave({
        param($s,$e)
        $chkInPanel = $s.Controls | Where-Object {$_ -is [System.Windows.Forms.CheckBox]} | Select-Object -First 1
        if (-not ($chkInPanel -and $chkInPanel.Checked)) {
            $s.BackColor = $corPainel
        }
    })
 
    # Linha separadora sutil bottom
    $pnlApp.add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(18, 28, 22), 1)
        $e.Graphics.DrawLine($pen, 12, $s.Height - 1, $s.Width - 12, $s.Height - 1)
        $pen.Dispose()
    })
 
    # Bullet / marcador dourado
    $pnlBullet = New-Object System.Windows.Forms.Panel
    $pnlBullet.Location  = New-Object System.Drawing.Point(16, 17)
    $pnlBullet.Size      = New-Object System.Drawing.Size(8, 8)
    $pnlBullet.BackColor = $corAmareloDim
    $pnlBullet.add_Paint({
        param($s, $e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(78, 60, 10))
        $e.Graphics.FillEllipse($br, 0, 0, 7, 7)
        $br.Dispose()
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(251, 191, 36), 1)
        $e.Graphics.DrawEllipse($pen, 0, 0, 7, 7)
        $pen.Dispose()
    })
    $pnlApp.Controls.Add($pnlBullet)
 
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text      = $app.Nome
    $chk.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $chk.ForeColor = $corTexto
    $chk.BackColor = [System.Drawing.Color]::Transparent
    $chk.Location  = New-Object System.Drawing.Point(34, 11)
    $chk.Size      = New-Object System.Drawing.Size(280, 22)
    $chk.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $chk.add_CheckedChanged({
        Atualizar-ContadorInst
        $parentPnl = $this.Parent
        if ($this.Checked) {
            $this.ForeColor = $corDestaque
            $parentPnl.BackColor = [System.Drawing.Color]::FromArgb(14, 24, 18)
        } else {
            $this.ForeColor = $corTexto
            $parentPnl.BackColor = $corPainel
        }
    })
    $pnlApp.Controls.Add($chk)
 
    $lblDesc = New-Object System.Windows.Forms.Label
    $lblDesc.Text      = $app.Desc
    $lblDesc.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
    $lblDesc.ForeColor = $corTextoMedio
    $lblDesc.Location  = New-Object System.Drawing.Point(324, 14)
    $lblDesc.Size      = New-Object System.Drawing.Size(368, 16)
    $lblDesc.BackColor = [System.Drawing.Color]::Transparent
    $pnlApp.Controls.Add($lblDesc)
 
    # Winget ID label (pequeno, canto direito)
    $lblWingetId = New-Object System.Windows.Forms.Label
    $lblWingetId.Text      = $app.Winget
    $lblWingetId.Font      = New-Object System.Drawing.Font("Consolas", 7)
    $lblWingetId.ForeColor = [System.Drawing.Color]::FromArgb(40, 55, 48)
    $lblWingetId.Location  = New-Object System.Drawing.Point(324, 26)
    $lblWingetId.Size      = New-Object System.Drawing.Size(368, 14)
    $lblWingetId.BackColor = [System.Drawing.Color]::Transparent
    $pnlApp.Controls.Add($lblWingetId)
 
    $pnlBlocoIndiv.Controls.Add($pnlApp)
    $script:chksIndividuais += $chk
    $yChk += 42
}
 
$alturaBloco2 = 46 + ($appsIndividuais.Count * 42) + 14
$pnlBlocoIndiv.Size = New-Object System.Drawing.Size(706, $alturaBloco2)
$pnlInstScroll.Controls.Add($pnlBlocoIndiv)
 
# Limpar selecao
$btnLimparInst.add_Click({
    $script:chkBasicos.Checked  = $false
    $script:chkBasicos.ForeColor = $corTextoClaro
    foreach ($chk in $script:chksIndividuais) {
        $chk.Checked   = $false
        $chk.ForeColor = $corTexto
        if ($chk.Parent) { $chk.Parent.BackColor = $corPainel }
    }
    Atualizar-ContadorInst
})
 
# Botao instalar premium (dock bottom)
$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text      = "  INSTALAR SELECIONADOS"
$btnInstalar.Dock      = "Bottom"
$btnInstalar.Height    = 52
$btnInstalar.BackColor = $corDestaque
$btnInstalar.ForeColor = [System.Drawing.Color]::FromArgb(8, 20, 14)
$btnInstalar.FlatStyle = "Flat"
$btnInstalar.FlatAppearance.BorderSize = 0
$btnInstalar.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnInstalar.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnInstalar.add_Paint({
    param($s, $e)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF($s.Width, 0)),
        [System.Drawing.Color]::FromArgb(52, 211, 153),
        [System.Drawing.Color]::FromArgb(16, 185, 129)
    )
    $e.Graphics.FillRectangle($grad, 0, 0, $s.Width, $s.Height)
    $grad.Dispose()
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $fnt = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $e.Graphics.DrawString($s.Text, $fnt, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(8,20,14))), (New-Object System.Drawing.RectangleF(0, 0, $s.Width, $s.Height)), $sf)
    $fnt.Dispose(); $sf.Dispose()
})
$script:btnInstalar = $btnInstalar
 
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
$pInst.Controls.Add($pnlPageHdr)
$pInst.Controls.Add($btnInstalar)
 
# =================================================================
#  ABA 1 - SISTEMA - REDESIGN PREMIUM
# =================================================================
$pSis = $tabPanels[1]
 
$pnlSisScroll = New-Object System.Windows.Forms.Panel
$pnlSisScroll.Dock       = "Fill"
$pnlSisScroll.BackColor  = $corFundo
$pnlSisScroll.AutoScroll = $true
 
# Page Header do Sistema
$pnlSisHdr = New-Object System.Windows.Forms.Panel
$pnlSisHdr.Dock      = "Top"
$pnlSisHdr.Height    = 60
$pnlSisHdr.BackColor = $corPainelAlt
$pnlSisHdr.add_Paint({
    param($s, $e)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 34, 28), 1)
    $e.Graphics.DrawLine($pen, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $pen.Dispose()
    $br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(251, 191, 36))
    $e.Graphics.FillRectangle($br, 0, 0, 3, $s.Height)
    $br.Dispose()
})
 
$lblSisTit = New-Object System.Windows.Forms.Label
$lblSisTit.Text      = "Ferramentas do Sistema"
$lblSisTit.Font      = New-Object System.Drawing.Font("Segoe UI Semibold", 14, [System.Drawing.FontStyle]::Bold)
$lblSisTit.ForeColor = $corTextoClaro
$lblSisTit.Location  = New-Object System.Drawing.Point(18, 10)
$lblSisTit.AutoSize  = $true
$lblSisTit.BackColor = [System.Drawing.Color]::Transparent
 
$lblSisSub = New-Object System.Windows.Forms.Label
$lblSisSub.Text      = "Manutencao, diagnostico e configuracoes do Windows"
$lblSisSub.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblSisSub.ForeColor = $corTextoMedio
$lblSisSub.Location  = New-Object System.Drawing.Point(18, 36)
$lblSisSub.AutoSize  = $true
$lblSisSub.BackColor = [System.Drawing.Color]::Transparent
 
$pnlSisHdr.Controls.AddRange(@($lblSisTit, $lblSisSub))
 
# Grid 2 colunas para os botoes de sistema
$sisAcoes = @(
    @{ Txt="Hardware Detalhado";       Desc="CPU, RAM, slots, placa-mae, SSD/HD";               Cor=$corDestaque;  Cmd="hwinfo";   Cat="Diagnostico"  }
    @{ Txt="Limpeza de Disco";         Desc="Remove temporarios, cache e Prefetch";              Cor=$corDestaque;  Cmd="limpeza";  Cat="Manutencao"   }
    @{ Txt="SFC /scannow";             Desc="Verifica e repara arquivos do sistema";             Cor=$corAmarelo;   Cmd="sfc";      Cat="Reparo"       }
    @{ Txt="DISM RestoreHealth";       Desc="Repara imagem do Windows";                         Cor=$corAmarelo;   Cmd="dism";     Cat="Reparo"       }
    @{ Txt="Checar Disco (chkdsk)";    Desc="Verifica integridade do disco C:";                 Cor=$corDestaque;  Cmd="chkdsk";   Cat="Diagnostico"  }
    @{ Txt="Flush DNS";                Desc="Limpa cache DNS do sistema";                       Cor=$corVerdeDim;  Cmd="dns";      Cat="Rede"         }
    @{ Txt="Reiniciar Explorer";       Desc="Reinicia o Explorer sem reiniciar o PC";           Cor=$corVerdeDim;  Cmd="exp";      Cat="Interface"    }
    @{ Txt="Gerenc. de Tarefas";       Desc="Abre o Gerenciador de Tarefas";                    Cor=$corVerdeDim;  Cmd="taskmgr";  Cat="Ferramentas"  }
    @{ Txt="Editor de Registro";       Desc="Abre o Regedit";                                   Cor=$corAmareloDim;Cmd="regedit";  Cat="Avancado"     }
    @{ Txt="Windows Update";           Desc="Abre as configuracoes de atualizacao";             Cor=$corVerdeDim;  Cmd="wupd";     Cat="Atualizacao"  }
    @{ Txt="Reiniciar PC";             Desc="Reinicia o computador imediatamente";              Cor=$corVermelhoDim;Cmd="reboot";  Cat="Sistema"      }
)
 
# Renderizar em grid 2 colunas
$colWidth  = 344
$rowHeight = 86
$padX      = 14
$padY      = 14
$col = 0; $row = 0
 
foreach ($a in $sisAcoes) {
    $xPos = $padX + ($col * ($colWidth + 10))
    $yPos = $padY + ($row * ($rowHeight + 10))
 
    $pnlCard = New-Object System.Windows.Forms.Panel
    $pnlCard.Location  = New-Object System.Drawing.Point($xPos, $yPos)
    $pnlCard.Size      = New-Object System.Drawing.Size($colWidth, $rowHeight)
    $pnlCard.BackColor = $corPainel
    $pnlCard.Tag       = $a.Cor
 
    # Paint do card com borda e acento
    $corCmd = $a.Cor
    $pnlCard.add_Paint({
        param($s, $e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        # Fundo
        $br = New-Object System.Drawing.SolidBrush($s.BackColor)
        $e.Graphics.FillRectangle($br, 0, 0, $s.Width, $s.Height)
        $br.Dispose()
        # Borda
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 34, 28), 1)
        $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1)
        $pen.Dispose()
        # Linha colorida topo (3px)
        $br2 = New-Object System.Drawing.SolidBrush($s.Tag)
        $e.Graphics.FillRectangle($br2, 0, 0, $s.Width, 3)
        $br2.Dispose()
    })
 
    # Botao principal (ocupa card inteiro)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = ""
    $btn.Location  = New-Object System.Drawing.Point(0, 0)
    $btn.Size      = New-Object System.Drawing.Size($colWidth, $rowHeight)
    $btn.BackColor = [System.Drawing.Color]::Transparent
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize         = 0
    $btn.FlatAppearance.MouseOverBackColor = $corPainelHov
    $btn.Tag       = $a.Cmd
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
 
    # Paint customizado do botao
    $corAcento = $a.Cor
    $txtBtn    = $a.Txt
    $descBtn   = $a.Desc
    $catBtn    = $a.Cat
    $btn.add_Paint({
        param($s, $e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        # Acento lateral esquerdo
        $br = New-Object System.Drawing.SolidBrush($corAcento)
        $e.Graphics.FillRectangle($br, 0, 3, 3, $s.Height - 3)
        $br.Dispose()
        # Titulo
        $fntTit = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $e.Graphics.DrawString($txtBtn, $fntTit, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(226,232,240))), 16, 12)
        $fntTit.Dispose()
        # Descricao
        $fntDesc = New-Object System.Drawing.Font("Segoe UI", 8)
        $e.Graphics.DrawString($descBtn, $fntDesc, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100,116,139))), 16, 34)
        $fntDesc.Dispose()
        # Badge da categoria
        $fntCat = New-Object System.Drawing.Font("Segoe UI", 6, [System.Drawing.FontStyle]::Bold)
        $catW   = [int]($catBtn.Length * 5.8) + 12
        $brCat  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 30, 24))
        $e.Graphics.FillRectangle($brCat, 16, 58, $catW, 16)
        $brCat.Dispose()
        $e.Graphics.DrawString($catBtn, $fntCat, (New-Object System.Drawing.SolidBrush($corAcento)), 20, 60)
        $fntCat.Dispose()
        # Seta indicativa à direita
        $fntArr = New-Object System.Drawing.Font("Segoe UI", 14)
        $e.Graphics.DrawString(">", $fntArr, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 45, 35))), ($s.Width - 28), 30)
        $fntArr.Dispose()
    }.GetNewClosure())
 
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
 
    $pnlCard.Controls.Add($btn)
    $pnlSisScroll.Controls.Add($pnlCard)
 
    $col++
    if ($col -ge 2) { $col = 0; $row++ }
}
 
$pSis.Controls.Add($pnlSisScroll)
$pSis.Controls.Add($pnlSisHdr)
 
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