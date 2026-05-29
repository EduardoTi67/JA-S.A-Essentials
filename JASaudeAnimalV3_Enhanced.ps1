# ============================================================
#  JA Saude Animal - Ferramenta de TI
#  by JA Saude Animal
#  v1.1 - Instalacao de Programas + Ferramentas de Sistema (VISUAL ENHANCED)
# ============================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#  PALETA PREMIUM 2026 - Dark Emerald Enhanced
#  Fundo escuro profundo + verde esmeralda + dourado com Glassmorphism
# ============================================================

# --- Fundos ---
$corFundo        = [System.Drawing.Color]::FromArgb(10,  14,  20)   # quase preto azulado
$corPainel       = [System.Drawing.Color]::FromArgb(16,  22,  30)   # card escuro
$corPainelHov    = [System.Drawing.Color]::FromArgb(22,  30,  40)   # card hover
$corPainelAlt    = [System.Drawing.Color]::FromArgb(13,  18,  25)   # alt background
$corPainelGlass  = [System.Drawing.Color]::FromArgb(25,  35,  45)   # glassmorphism base

# --- Bordas e separadores ---
$corBorda        = [System.Drawing.Color]::FromArgb(30,  45,  35)
$corBordaSutil   = [System.Drawing.Color]::FromArgb(22,  34,  28)
$corBordaBrilho  = [System.Drawing.Color]::FromArgb(46, 139, 87)
$corBordaGlass   = [System.Drawing.Color]::FromArgb(52, 211, 153)   # borda com destaque

# --- Verdes (marca) ---
$corDestaque     = [System.Drawing.Color]::FromArgb(52, 211, 153)   # emerald-400 vibrante
$corDestaqueHov  = [System.Drawing.Color]::FromArgb(16, 185, 129)   # emerald-500
$corDestaqueDark = [System.Drawing.Color]::FromArgb(6,  95,  70)    # emerald deep
$corVerde        = [System.Drawing.Color]::FromArgb(52, 211, 153)
$corVerdeDim     = [System.Drawing.Color]::FromArgb(20, 80,  55)    # verde escurecido p/ backgrounds
$corVerdeGlow    = [System.Drawing.Color]::FromArgb(31, 120, 90)
$corVerdeLight   = [System.Drawing.Color]::FromArgb(110, 240, 200)  # destaque claro

# --- Amarelo/dourado (acento) ---
$corAmarelo      = [System.Drawing.Color]::FromArgb(251, 191, 36)   # amber-400
$corAmareloHov   = [System.Drawing.Color]::FromArgb(245, 158, 11)   # amber-500
$corAmareloDim   = [System.Drawing.Color]::FromArgb(78,  60,  10)   # amber background
$corAmareLite    = [System.Drawing.Color]::FromArgb(255, 220, 100)  # amber light

# --- Alerta / Perigo ---
$corVermelho     = [System.Drawing.Color]::FromArgb(248,  81,  73)
$corVermelhoDim  = [System.Drawing.Color]::FromArgb(80,  20,  20)

# --- Textos ---
$corTexto        = [System.Drawing.Color]::FromArgb(226, 232, 240)  # slate-200 (texto principal)
$corTextoClaro   = [System.Drawing.Color]::FromArgb(255, 255, 255)
$corTextoEscuro  = [System.Drawing.Color]::FromArgb(100, 116, 139)  # slate-500
$corTextoMedio   = [System.Drawing.Color]::FromArgb(148, 163, 184)  # slate-400
$corTextoSutil   = [System.Drawing.Color]::FromArgb(71, 85, 105)    # slate-600

# --- Sidebar ---
$corSidebar      = [System.Drawing.Color]::FromArgb(8,   12,  17)   # sidebar quase preta
$corSidebarText  = [System.Drawing.Color]::FromArgb(148, 163, 184)
$corSidebarHov   = [System.Drawing.Color]::FromArgb(20,  30,  22)
$corSidebarSel   = [System.Drawing.Color]::FromArgb(14,  50,  36)   # selecionado: verde escuro

# =================================================================
#  FUNCAO HELPER - Desenhar card com sombra e glassmorphism
# =================================================================
function Desenhar-CardModerno {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.RectangleF]$Rect,
        [System.Drawing.Color]$CorPrincipal,
        [System.Drawing.Color]$CorBorda = $corDestaque,
        [bool]$ComSombra = $true,
        [int]$RaioCantos = 8
    )
    
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddRoundedRectangle($Rect, $RaioCantos)
    
    # Sombra (se enabled)
    if ($ComSombra) {
        $shadowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $shadowRect = New-Object System.Drawing.RectangleF($Rect.X + 2, $Rect.Y + 2, $Rect.Width, $Rect.Height)
        $shadowPath.AddRoundedRectangle($shadowRect, $RaioCantos)
        $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 0, 0, 0))
        $Graphics.FillPath($shadowBrush, $shadowPath)
        $shadowBrush.Dispose()
        $shadowPath.Dispose()
    }
    
    # Preenchimento glassmorphic
    $glassGrad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF($Rect.X, $Rect.Y)),
        (New-Object System.Drawing.PointF($Rect.X, $Rect.Y + $Rect.Height)),
        [System.Drawing.Color]::FromArgb(40, $CorPrincipal),
        [System.Drawing.Color]::FromArgb(20, $CorPrincipal)
    )
    $Graphics.FillPath($glassGrad, $path)
    $glassGrad.Dispose()
    
    # Borda sofisticada
    $penBorda = New-Object System.Drawing.Pen($CorBorda, 1.5)
    $Graphics.DrawPath($penBorda, $path)
    $penBorda.Dispose()
    
    $path.Dispose()
}

# Estender GraphicsPath com metodo para cantos arredondados
if (-not ([System.Drawing.Drawing2D.GraphicsPath].GetMethod("AddRoundedRectangle"))) {
    Add-Type -TypeDefinition @"
public static class GraphicsPathExtension {
    public static void AddRoundedRectangle(this System.Drawing.Drawing2D.GraphicsPath path, System.Drawing.RectangleF rect, int radius) {
        path.AddArc(rect.X, rect.Y, radius * 2, radius * 2, 180, 90);
        path.AddArc(rect.X + rect.Width - radius * 2, rect.Y, radius * 2, radius * 2, 270, 90);
        path.AddArc(rect.X + rect.Width - radius * 2, rect.Y + rect.Height - radius * 2, radius * 2, radius * 2, 0, 90);
        path.AddArc(rect.X, rect.Y + rect.Height - radius * 2, radius * 2, radius * 2, 90, 90);
        path.CloseFigure();
    }
}
"@
}

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

    # Fundo circular com gradiente esmeralda sofisticado
    $gradFundo = New-Object System.Drawing.Drawing2D.RadialGradientBrush(
        (New-Object System.Drawing.PointF(16, 16)),
        16,
        [System.Drawing.Color]::FromArgb(110, 240, 200),
        [System.Drawing.Color]::FromArgb(6, 95, 70)
    )
    $g.FillEllipse($gradFundo, 0, 0, 31, 31)
    $gradFundo.Dispose()
    
    # Aro externo brilhante
    $penAro = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(52, 211, 153), 1.5)
    $g.DrawEllipse($penAro, 0, 0, 31, 31)
    $penAro.Dispose()

    # Cruz branca com efeito de brilho
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

$appsBasicos = @(
    @{ Nome="Firefox";                  Winget="Mozilla.Firefox" }
    @{ Nome="Google Chrome";            Winget="Google.Chrome" }
    @{ Nome="Microsoft Edge";           Winget="Microsoft.Edge" }
    @{ Nome="7-Zip";                    Winget="7zip.7zip" }
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
    @{ Nome=".NET Desktop Runtime 8 x86"; Winget="Microsoft.DotNet.DesktopRuntime.8.x86" }
    @{ Nome=".NET Desktop Runtime 8 x64"; Winget="Microsoft.DotNet.DesktopRuntime.8.x64" }
    @{ Nome=".NET Desktop Runtime 9"; Winget="Microsoft.DotNet.DesktopRuntime.9" }
    @{ Nome=".NET Desktop Runtime 10";Winget="Microsoft.DotNet.DesktopRuntime.10" }
    @{ Nome="OneDrive";                 Winget="Microsoft.OneDrive" }
    @{ Nome="Zoom";                     Winget="Zoom.Zoom" }
    @{ Nome="Microsoft Teams";          Winget="Microsoft.Teams" }
    @{ Nome="TeamViewer 15";            Winget="TeamViewer.TeamViewer" }
)

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
#  JANELA PRINCIPAL - REDESIGN PREMIUM 2026 ENHANCED
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

# --- Barra de acento topo (gradiente verde-azul esmeralda com efeito) ---
$pnlAccent = New-Object System.Windows.Forms.Panel
$pnlAccent.Dock      = "Top"
$pnlAccent.Height    = 4
$pnlAccent.BackColor = $corDestaque
$pnlAccent.add_Paint({
    param($s, $e)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF($s.Width, 0)),
        [System.Drawing.Color]::FromArgb(52, 211, 153),
        [System.Drawing.Color]::FromArgb(110, 240, 200)
    )
    $e.Graphics.FillRectangle($grad, 0, 0, $s.Width, $s.Height)
    $grad.Dispose()
})
$script:form.Controls.Add($pnlAccent)

# --- Header premium com efeito glassmorphism ---
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock      = "Top"
$pnlHeader.Height    = 68
$pnlHeader.BackColor = $corSidebar

$pnlHeader.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Fundo glassmorphic
    $rect  = New-Object System.Drawing.Rectangle(0, 0, $s.Width, $s.Height)
    $grad  = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF($s.Width, 0)),
        [System.Drawing.Color]::FromArgb(8, 12, 17),
        [System.Drawing.Color]::FromArgb(14, 22, 18)
    )
    $e.Graphics.FillRectangle($grad, $rect)
    $grad.Dispose()
    
    # Linha inferior esmeralda com brilho
    $penLine = New-Object System.Drawing.Pen($corDestaque, 2)
    $e.Graphics.DrawLine($penLine, 0, $s.Height - 2, $s.Width, $s.Height - 2)
    $penLine.Dispose()
    
    # Sublinha com efeito glow
    $penGlow = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(100, 52, 211, 153), 1)
    $e.Graphics.DrawLine($penGlow, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $penGlow.Dispose()
})

# Icone decorativo com animação simulada
$pnlDot = New-Object System.Windows.Forms.Panel
$pnlDot.Location  = New-Object System.Drawing.Point(18, 24)
$pnlDot.Size      = New-Object System.Drawing.Size(20, 20)
$pnlDot.BackColor = $corDestaque
$pnlDot.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Círculo externo com gradiente radial
    $gradCirc = New-Object System.Drawing.Drawing2D.RadialGradientBrush(
        (New-Object System.Drawing.PointF(10, 10)),
        12,
        [System.Drawing.Color]::FromArgb(52, 211, 153),
        [System.Drawing.Color]::FromArgb(20, 95, 70)
    )
    $e.Graphics.FillEllipse($gradCirc, 0, 0, 19, 19)
    $gradCirc.Dispose()
    
    # Aro brilhante
    $penAro = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(110, 240, 200), 1.5)
    $e.Graphics.DrawEllipse($penAro, 0, 0, 19, 19)
    $penAro.Dispose()
    
    # Brilho interno
    $brushGlow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 255, 255))
    $e.Graphics.FillEllipse($brushGlow, 3, 2, 8, 8)
    $brushGlow.Dispose()
})

$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text      = "JA Saude Animal"
$lblTitulo.Font      = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$lblTitulo.ForeColor = $corTextoClaro
$lblTitulo.Location  = New-Object System.Drawing.Point(46, 8)
$lblTitulo.AutoSize  = $true
$lblTitulo.BackColor = [System.Drawing.Color]::Transparent

$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text      = "v1.1 Enhanced"
$lblVersion.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$lblVersion.ForeColor = $corVerdeLight
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

# Badge "ADMIN" melhorado no canto direito do header
$pnlBadge = New-Object System.Windows.Forms.Panel
$pnlBadge.Size      = New-Object System.Drawing.Size(100, 28)
$pnlBadge.BackColor = $corVerdeDim
$pnlBadge.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Fundo glassmorphic
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddRoundedRectangle((New-Object System.Drawing.RectangleF(0, 0, $s.Width - 1, $s.Height - 1)), 4)
    
    $glassGrad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(0, $s.Height)),
        [System.Drawing.Color]::FromArgb(80, 52, 211, 153),
        [System.Drawing.Color]::FromArgb(40, 52, 211, 153)
    )
    $e.Graphics.FillPath($glassGrad, $path)
    $glassGrad.Dispose()
    
    # Borda com brilho
    $penBord = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(110, 240, 200), 1.5)
    $e.Graphics.DrawPath($penBord, $path)
    $penBord.Dispose()
    
    # Texto
    $lblF = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
    $sf   = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $e.Graphics.DrawString("✓ ADMIN", $lblF, (New-Object System.Drawing.SolidBrush($corTextoClaro)), (New-Object System.Drawing.RectangleF(0, 0, $s.Width, $s.Height)), $sf)
    $lblF.Dispose()
    $sf.Dispose()
    
    $path.Dispose()
})
$pnlBadge.Location = New-Object System.Drawing.Point(880, 20)

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
#  SIDEBAR PREMIUM COM GLASSMORPHISM
# =================================================================
$pnlSidebar = New-Object System.Windows.Forms.Panel
$pnlSidebar.Location  = New-Object System.Drawing.Point(0, 0)
$pnlSidebar.Size      = New-Object System.Drawing.Size(210, 676)
$pnlSidebar.Anchor    = "Top,Left,Bottom"
$pnlSidebar.BackColor = $corSidebar

$pnlSidebar.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Gradiente sofisticado com glassmorphism
    $rect = New-Object System.Drawing.Rectangle(0, 0, $s.Width, $s.Height)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF($s.Width, 0)),
        [System.Drawing.Color]::FromArgb(8, 12, 17),
        [System.Drawing.Color]::FromArgb(12, 18, 22)
    )
    $e.Graphics.FillRectangle($grad, $rect)
    $grad.Dispose()
    
    # Linha direita de separação com brilho
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 52, 211, 153), 1)
    $e.Graphics.DrawLine($pen, $s.Width - 1, 0, $s.Width - 1, $s.Height)
    $pen.Dispose()
})

$pnlMain.Controls.Add($pnlSidebar)

# Logo / avatar na sidebar - melhorado
$pnlSidelogo = New-Object System.Windows.Forms.Panel
$pnlSidelogo.Location  = New-Object System.Drawing.Point(0, 0)
$pnlSidelogo.Size      = New-Object System.Drawing.Size(210, 88)
$pnlSidelogo.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 12)
$pnlSidelogo.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Fundo com gradiente
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(0, $s.Height)),
        [System.Drawing.Color]::FromArgb(15, 24, 20),
        [System.Drawing.Color]::FromArgb(10, 16, 12)
    )
    $e.Graphics.FillRectangle($grad, 0, 0, $s.Width, $s.Height)
    $grad.Dispose()
    
    # Cruz médica com efeito de brilho
    $penCruz = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(52, 211, 153), 4)
    $penCruz.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penCruz.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $e.Graphics.DrawLine($penCruz, 24, 30, 24, 50)
    $e.Graphics.DrawLine($penCruz, 14, 40, 34, 40)
    $penCruz.Dispose()
    
    # Circulo ao redor com gradiente
    $penCirc = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(110, 240, 200), 2)
    $e.Graphics.DrawEllipse($penCirc, 6, 18, 36, 36)
    $penCirc.Dispose()
    
    # Texto com efeito shadow
    $fnt  = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $fnt2 = New-Object System.Drawing.Font("Segoe UI", 6, [System.Drawing.FontStyle]::Bold)
    
    # Shadow
    $e.Graphics.DrawString("JA Saude", $fnt, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 0, 0, 0))), 51, 23)
    $e.Graphics.DrawString("Animal", $fnt, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 0, 0, 0))), 51, 43)
    
    # Texto principal
    $e.Graphics.DrawString("JA Saude", $fnt, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(226,232,240))), 50, 22)
    $e.Graphics.DrawString("Animal", $fnt, (New-Object System.Drawing.SolidBrush($corDestaque)), 50, 42)
    $e.Graphics.DrawString("v1.1 Enhanced", $fnt2, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100,116,139))), 50, 65)
    
    $fnt.Dispose(); $fnt2.Dispose()
    
    # Linha inferior com gradiente
    $penSep = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 52, 211, 153), 1)
    $e.Graphics.DrawLine($penSep, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $penSep.Dispose()
})
$pnlSidebar.Controls.Add($pnlSidelogo)

# Separador de secao na sidebar
$pnlNavLabel = New-Object System.Windows.Forms.Panel
$pnlNavLabel.Location  = New-Object System.Drawing.Point(0, 88)
$pnlNavLabel.Size      = New-Object System.Drawing.Size(210, 32)
$pnlNavLabel.BackColor = [System.Drawing.Color]::FromArgb(8, 12, 17)
$lblNavSec = New-Object System.Windows.Forms.Label
$lblNavSec.Text      = "  ▸ NAVEGACAO"
$lblNavSec.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
$lblNavSec.ForeColor = [System.Drawing.Color]::FromArgb(52, 211, 153)
$lblNavSec.Location  = New-Object System.Drawing.Point(10, 10)
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

# --- LOG panel com glassmorphism ---
$pnlLogOuter = New-Object System.Windows.Forms.Panel
$pnlLogOuter.Location  = New-Object System.Drawing.Point(960, 0)
$pnlLogOuter.Size      = New-Object System.Drawing.Size(240, 676)
$pnlLogOuter.Anchor    = "Top,Right,Bottom"
$pnlLogOuter.BackColor = $corSidebar
$pnlLogOuter.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Gradiente sofisticado
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF($s.Width, 0)),
        [System.Drawing.Color]::FromArgb(12, 18, 22),
        [System.Drawing.Color]::FromArgb(8, 12, 17)
    )
    $e.Graphics.FillRectangle($grad, 0, 0, $s.Width, $s.Height)
    $grad.Dispose()
    
    # Borda esquerda com brilho verde
    $penBord = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(52, 211, 153), 1.5)
    $e.Graphics.DrawLine($penBord, 0, 0, 0, $s.Height)
    $penBord.Dispose()
})
$pnlMain.Controls.Add($pnlLogOuter)

# Header do Log
$pnlLogHeader = New-Object System.Windows.Forms.Panel
$pnlLogHeader.Location  = New-Object System.Drawing.Point(0, 0)
$pnlLogHeader.Size      = New-Object System.Drawing.Size(240, 44)
$pnlLogHeader.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 12)
$pnlLogHeader.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Fundo
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 52, 211, 153), 1)
    $e.Graphics.DrawLine($pen, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $pen.Dispose()
    
    # Ponto verde pulsante
    $br = New-Object System.Drawing.SolidBrush($corDestaque)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $e.Graphics.FillEllipse($br, 12, 16, 6, 6)
    $br.Dispose()
})
$lblLogTitH = New-Object System.Windows.Forms.Label
$lblLogTitH.Text      = "  ◆ LOG DE ATIVIDADES"
$lblLogTitH.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
$lblLogTitH.ForeColor = $corDestaque
$lblLogTitH.Location  = New-Object System.Drawing.Point(0, 13)
$lblLogTitH.Size      = New-Object System.Drawing.Size(240, 18)
$lblLogTitH.BackColor = [System.Drawing.Color]::Transparent
$pnlLogHeader.Controls.Add($lblLogTitH)
$pnlLogOuter.Controls.Add($pnlLogHeader)

$pnlLog = $pnlLogOuter

# =================================================================
#  TABS - SIDEBAR BUTTONS PREMIUM COM ANIMAÇÃO
# =================================================================
$tabDefs = @(
    @{ Label="Instalar Programas"; Icon="⊕" }
    @{ Label="Sistema";            Icon="⚙" }
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

$yBtn = 128
foreach ($def in $tabDefs) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = "  $($def.Icon)  $($def.Label)"
    $btn.Location  = New-Object System.Drawing.Point(6, $yBtn)
    $btn.Size      = New-Object System.Drawing.Size(198, 44)
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
    $btn.add_Paint({
        param($s, $e)
        if ($s.BackColor -eq $corSidebarSel) {
            # Acento verde esquerda
            $brAccent = New-Object System.Drawing.SolidBrush($corDestaque)
            $e.Graphics.FillRectangle($brAccent, 0, 0, 3, $s.Height)
            $brAccent.Dispose()
        }
    })
    
    $pnl = Criar-TabPanel
    $tabPanels.Add($pnl)  | Out-Null
    $tabButtons.Add($btn) | Out-Null
    $btn.add_Click({ Selecionar-Tab -idx $this.Tag })
    $pnlSidebar.Controls.Add($btn)
    $yBtn += 52
}

# Linha separadora na sidebar
$sepSideLine = New-Object System.Windows.Forms.Panel
$sepSideLine.Location  = New-Object System.Drawing.Point(20, ($yBtn + 10))
$sepSideLine.Size      = New-Object System.Drawing.Size(170, 1)
$sepSideLine.BackColor = [System.Drawing.Color]::FromArgb(30, 52, 211, 153)
$pnlSidebar.Controls.Add($sepSideLine)

# Status do sistema na parte inferior da sidebar
$pnlSideStatus = New-Object System.Windows.Forms.Panel
$pnlSideStatus.Location  = New-Object System.Drawing.Point(0, 590)
$pnlSideStatus.Size      = New-Object System.Drawing.Size(210, 86)
$pnlSideStatus.BackColor = [System.Drawing.Color]::FromArgb(8, 12, 17)
$pnlSideStatus.Anchor    = "Bottom,Left"
$pnlSideStatus.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Gradiente sutil
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(0, $s.Height)),
        [System.Drawing.Color]::FromArgb(12, 18, 22),
        [System.Drawing.Color]::FromArgb(8, 12, 17)
    )
    $e.Graphics.FillRectangle($grad, 0, 0, $s.Width, $s.Height)
    $grad.Dispose()
    
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 52, 211, 153), 1)
    $e.Graphics.DrawLine($pen, 0, 0, $s.Width, 0)
    $pen.Dispose()
})

$lblSideUser = New-Object System.Windows.Forms.Label
$lblSideUser.Text      = "👤 $env:USERNAME"
$lblSideUser.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
$lblSideUser.ForeColor = $corTextoMedio
$lblSideUser.Location  = New-Object System.Drawing.Point(12, 12)
$lblSideUser.Size      = New-Object System.Drawing.Size(186, 16)
$lblSideUser.BackColor = [System.Drawing.Color]::Transparent

$lblSideMaq = New-Object System.Windows.Forms.Label
$lblSideMaq.Text      = "💻 $env:COMPUTERNAME"
$lblSideMaq.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
$lblSideMaq.ForeColor = $corTextoMedio
$lblSideMaq.Location  = New-Object System.Drawing.Point(12, 30)
$lblSideMaq.Size      = New-Object System.Drawing.Size(186, 16)
$lblSideMaq.BackColor = [System.Drawing.Color]::Transparent

$lblSideCopy = New-Object System.Windows.Forms.Label
$lblSideCopy.Text      = "JA Saude Animal • TI"
$lblSideCopy.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
$lblSideCopy.ForeColor = $corDestaque
$lblSideCopy.Location  = New-Object System.Drawing.Point(12, 60)
$lblSideCopy.AutoSize  = $true
$lblSideCopy.BackColor = [System.Drawing.Color]::Transparent

$pnlSideStatus.Controls.AddRange(@($lblSideUser, $lblSideMaq, $lblSideCopy))
$pnlSidebar.Controls.Add($pnlSideStatus)

# =================================================================
#  ABA 0 - INSTALAR PROGRAMAS - PREMIUM ENHANCED
# =================================================================
$pInst = $tabPanels[0]

$pnlInstScroll = New-Object System.Windows.Forms.Panel
$pnlInstScroll.Dock       = "Fill"
$pnlInstScroll.BackColor  = $corFundo
$pnlInstScroll.AutoScroll = $true

# --- Page Header ---
$pnlPageHdr = New-Object System.Windows.Forms.Panel
$pnlPageHdr.Dock      = "Top"
$pnlPageHdr.Height    = 64
$pnlPageHdr.BackColor = $corPainelAlt
$pnlPageHdr.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 52, 211, 153), 1)
    $e.Graphics.DrawLine($pen, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $pen.Dispose()
    
    # Acento verde esquerda
    $gradAccent = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(0, $s.Height)),
        [System.Drawing.Color]::FromArgb(52, 211, 153),
        [System.Drawing.Color]::FromArgb(20, 95, 70)
    )
    $e.Graphics.FillRectangle($gradAccent, 0, 0, 4, $s.Height)
    $gradAccent.Dispose()
})

$lblPageTit = New-Object System.Windows.Forms.Label
$lblPageTit.Text      = "📦 Instalar Programas"
$lblPageTit.Font      = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblPageTit.ForeColor = $corTextoClaro
$lblPageTit.Location  = New-Object System.Drawing.Point(18, 6)
$lblPageTit.AutoSize  = $true
$lblPageTit.BackColor = [System.Drawing.Color]::Transparent

$lblPageSub = New-Object System.Windows.Forms.Label
$lblPageSub.Text      = "Selecione os pacotes desejados e clique em Instalar"
$lblPageSub.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblPageSub.ForeColor = $corTextoMedio
$lblPageSub.Location  = New-Object System.Drawing.Point(18, 38)
$lblPageSub.AutoSize  = $true
$lblPageSub.BackColor = [System.Drawing.Color]::Transparent

$script:lblContadorInst = New-Object System.Windows.Forms.Label
$script:lblContadorInst.Text      = "◇ 0 selecionado(s)"
$script:lblContadorInst.ForeColor = $corTextoMedio
$script:lblContadorInst.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$script:lblContadorInst.Location  = New-Object System.Drawing.Point(560, 18)
$script:lblContadorInst.AutoSize  = $true
$script:lblContadorInst.BackColor = [System.Drawing.Color]::Transparent

$btnLimparInst = New-Object System.Windows.Forms.Button
$btnLimparInst.Text      = "✕ Limpar"
$btnLimparInst.Location  = New-Object System.Drawing.Point(660, 16)
$btnLimparInst.Size      = New-Object System.Drawing.Size(80, 32)
$btnLimparInst.BackColor = [System.Drawing.Color]::FromArgb(22, 34, 28)
$btnLimparInst.ForeColor = $corTextoMedio
$btnLimparInst.FlatStyle = "Flat"
$btnLimparInst.FlatAppearance.BorderSize = 1
$btnLimparInst.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(30, 52, 211, 153)
$btnLimparInst.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$btnLimparInst.Cursor    = [System.Windows.Forms.Cursors]::Hand

$pnlPageHdr.Controls.AddRange(@($lblPageTit, $lblPageSub, $script:lblContadorInst, $btnLimparInst))

function Atualizar-ContadorInst {
    $total = 0
    if ($script:chkBasicos -and $script:chkBasicos.Checked) { $total++ }
    foreach ($chk in $script:chksIndividuais) {
        if ($chk.Checked) { $total++ }
    }
    $script:lblContadorInst.Text      = "◇ $total selecionado(s)"
    $script:lblContadorInst.ForeColor = if ($total -gt 0) { $corDestaque } else { $corTextoMedio }
}

# -------------------------------------------------------
#  BLOCO: PACOTE BASICO - CARD PREMIUM ENHANCED
# -------------------------------------------------------
$yScroll = 14

$pnlBlocoBasico = New-Object System.Windows.Forms.Panel
$pnlBlocoBasico.Location  = New-Object System.Drawing.Point(14, $yScroll)
$pnlBlocoBasico.Size      = New-Object System.Drawing.Size(706, 0)
$pnlBlocoBasico.BackColor = $corPainel
$pnlBlocoBasico.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Borda sutil ao redor do card com sombra
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 0, 0, 0))
    $e.Graphics.FillRectangle($shadowBrush, 2, 2, $s.Width - 4, $s.Height - 4)
    $shadowBrush.Dispose()
    
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 52, 211, 153), 1.5)
    $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1)
    $pen.Dispose()
    
    # Acento lateral verde degradê
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(0, $s.Height)),
        [System.Drawing.Color]::FromArgb(52, 211, 153),
        [System.Drawing.Color]::FromArgb(20, 95, 70)
    )
    $e.Graphics.FillRectangle($grad, 0, 0, 4, $s.Height)
    $grad.Dispose()
})

# Icone + titulo do bloco
$pnlBlocoHdr = New-Object System.Windows.Forms.Panel
$pnlBlocoHdr.Location  = New-Object System.Drawing.Point(4, 0)
$pnlBlocoHdr.Size      = New-Object System.Drawing.Size(699, 54)
$pnlBlocoHdr.BackColor = [System.Drawing.Color]::FromArgb(14, 20, 16)

$lblBasicoTit = New-Object System.Windows.Forms.Label
$lblBasicoTit.Text      = "  ⊚ Pacote Completo - Apps Essenciais"
$lblBasicoTit.Font      = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblBasicoTit.ForeColor = $corDestaque
$lblBasicoTit.Location  = New-Object System.Drawing.Point(10, 8)
$lblBasicoTit.AutoSize  = $true
$lblBasicoTit.BackColor = [System.Drawing.Color]::Transparent

$lblBasicoCount = New-Object System.Windows.Forms.Label
$lblBasicoCount.Text      = "24 itens · Navegadores, Drivers, Runtime, Comunicacao"
$lblBasicoCount.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblBasicoCount.ForeColor = $corTextoMedio
$lblBasicoCount.Location  = New-Object System.Drawing.Point(12, 32)
$lblBasicoCount.AutoSize  = $true
$lblBasicoCount.BackColor = [System.Drawing.Color]::Transparent

$pnlBlocoHdr.Controls.AddRange(@($lblBasicoTit, $lblBasicoCount))
$pnlBlocoBasico.Controls.Add($pnlBlocoHdr)

# Tags visuais dos apps inclusos - melhorados
$tagApps = @("Firefox","Chrome","Edge","7-Zip","VC Redist x86/x64","NET Runtime 8/9/10","OneDrive","Zoom","Teams","TeamViewer")
$xTag = 16; $yTag = 62
foreach ($tag in $tagApps) {
    $pnlTag = New-Object System.Windows.Forms.Panel
    $txtLen = ($tag.Length * 6.5) + 18
    $pnlTag.Size      = New-Object System.Drawing.Size($txtLen, 24)
    $pnlTag.BackColor = $corVerdeDim
    $pnlTag.add_Paint({
        param($s, $e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Fundo glassmorphic
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddRoundedRectangle((New-Object System.Drawing.RectangleF(0, 0, $s.Width - 1, $s.Height - 1)), 3)
        
        $glassGrad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.PointF(0, 0)),
            (New-Object System.Drawing.PointF(0, $s.Height)),
            [System.Drawing.Color]::FromArgb(50, 52, 211, 153),
            [System.Drawing.Color]::FromArgb(20, 52, 211, 153)
        )
        $e.Graphics.FillPath($glassGrad, $path)
        $glassGrad.Dispose()
        
        # Borda
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(31, 120, 90), 1.2)
        $e.Graphics.DrawPath($pen, $path)
        $pen.Dispose()
        
        $path.Dispose()
    })
    
    $lblTag = New-Object System.Windows.Forms.Label
    $lblTag.Text      = "• $tag"
    $lblTag.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
    $lblTag.ForeColor = $corVerdeLight
    $lblTag.Location  = New-Object System.Drawing.Point(7, 4)
    $lblTag.AutoSize  = $true
    $lblTag.BackColor = [System.Drawing.Color]::Transparent
    $pnlTag.Controls.Add($lblTag)

    if (($xTag + $txtLen + 8) -gt 695) { $xTag = 16; $yTag += 30 }
    $pnlTag.Location = New-Object System.Drawing.Point($xTag, $yTag)
    $xTag += $txtLen + 8
    $pnlBlocoBasico.Controls.Add($pnlTag)
}

# Separador
$sepBloco = New-Object System.Windows.Forms.Panel
$sepBloco.Location  = New-Object System.Drawing.Point(16, ($yTag + 32))
$sepBloco.Size      = New-Object System.Drawing.Size(674, 1)
$sepBloco.BackColor = [System.Drawing.Color]::FromArgb(30, 52, 211, 153)
$pnlBlocoBasico.Controls.Add($sepBloco)

# Checkbox principal - estilizado
$script:chkBasicos = New-Object System.Windows.Forms.CheckBox
$script:chkBasicos.Text      = "   ✓ Instalar todos os apps essenciais acima"
$script:chkBasicos.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:chkBasicos.ForeColor = $corTextoClaro
$script:chkBasicos.BackColor = [System.Drawing.Color]::Transparent
$script:chkBasicos.Location  = New-Object System.Drawing.Point(16, ($yTag + 42))
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

$alturaBloco1 = 54 + ($yTag - 62) + 30 + 28 + 16 + 18
$pnlBlocoBasico.Height = $alturaBloco1
$pnlInstScroll.Controls.Add($pnlBlocoBasico)

# -------------------------------------------------------
#  BLOCO: APPS INDIVIDUAIS - CARDS PREMIUM ENHANCED
# -------------------------------------------------------
$yScroll2 = $yScroll + $alturaBloco1 + 16

$pnlBlocoIndiv = New-Object System.Windows.Forms.Panel
$pnlBlocoIndiv.Location  = New-Object System.Drawing.Point(14, $yScroll2)
$pnlBlocoIndiv.BackColor = $corPainel
$pnlBlocoIndiv.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Sombra
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 0, 0, 0))
    $e.Graphics.FillRectangle($shadowBrush, 2, 2, $s.Width - 4, $s.Height - 4)
    $shadowBrush.Dispose()
    
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 52, 211, 153), 1.5)
    $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1)
    $pen.Dispose()
    
    # Acento lateral amarelo/dourado
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(0, $s.Height)),
        [System.Drawing.Color]::FromArgb(251, 191, 36),
        [System.Drawing.Color]::FromArgb(78, 60, 10)
    )
    $e.Graphics.FillRectangle($grad, 0, 0, 4, $s.Height)
    $grad.Dispose()
})

$pnlIndivHdr = New-Object System.Windows.Forms.Panel
$pnlIndivHdr.Location  = New-Object System.Drawing.Point(4, 0)
$pnlIndivHdr.Size      = New-Object System.Drawing.Size(699, 48)
$pnlIndivHdr.BackColor = [System.Drawing.Color]::FromArgb(20, 16, 8)

$lblIndivTit = New-Object System.Windows.Forms.Label
$lblIndivTit.Text      = "  ⊕ Aplicativos Adicionais"
$lblIndivTit.Font      = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblIndivTit.ForeColor = $corAmarelo
$lblIndivTit.Location  = New-Object System.Drawing.Point(10, 8)
$lblIndivTit.AutoSize  = $true
$lblIndivTit.BackColor = [System.Drawing.Color]::Transparent

$lblIndivSub = New-Object System.Windows.Forms.Label
$lblIndivSub.Text      = "Ferramentas opcionais | Selecione individualmente"
$lblIndivSub.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblIndivSub.ForeColor = $corTextoMedio
$lblIndivSub.Location  = New-Object System.Drawing.Point(12, 30)
$lblIndivSub.AutoSize  = $true
$lblIndivSub.BackColor = [System.Drawing.Color]::Transparent

$pnlIndivHdr.Controls.AddRange(@($lblIndivTit, $lblIndivSub))
$pnlBlocoIndiv.Controls.Add($pnlIndivHdr)

# Checkboxes individuais - estilo linha de tabela premium
$script:chksIndividuais = @()
$yChk = 48

foreach ($app in $appsIndividuais) {
    $pnlApp = New-Object System.Windows.Forms.Panel
    $pnlApp.Location  = New-Object System.Drawing.Point(4, $yChk)
    $pnlApp.Size      = New-Object System.Drawing.Size(699, 44)
    $pnlApp.BackColor = $corPainel
    $pnlApp.Tag       = $false

    # Hover effect melhorado
    $pnlApp.add_MouseEnter({
        param($s,$e)
        $chkInPanel = $s.Controls | Where-Object {$_ -is [System.Windows.Forms.CheckBox]} | Select-Object -First 1
        if ($chkInPanel -and -not $chkInPanel.Checked) {
            $s.BackColor = $corPainelHov
        }
    })
    $pnlApp.add_MouseLeave({
        param($s,$e)
        $chkInPanel = $s.Controls | Where-Object {$_ -is [System.Windows.Forms.CheckBox]} | Select-Object -First 1
        if ($chkInPanel -and -not $chkInPanel.Checked) {
            $s.BackColor = $corPainel
        }
    })

    # Linha separadora sutil bottom
    $pnlApp.add_Paint({
        param($s, $e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(25, 52, 211, 153), 1)
        $e.Graphics.DrawLine($pen, 12, $s.Height - 1, $s.Width - 12, $s.Height - 1)
        $pen.Dispose()
    })

    # Bullet / marcador dourado
    $pnlBullet = New-Object System.Windows.Forms.Panel
    $pnlBullet.Location  = New-Object System.Drawing.Point(16, 18)
    $pnlBullet.Size      = New-Object System.Drawing.Size(10, 10)
    $pnlBullet.BackColor = $corAmareloDim
    $pnlBullet.add_Paint({
        param($s, $e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Gradiente radial
        $gradRadial = New-Object System.Drawing.Drawing2D.RadialGradientBrush(
            (New-Object System.Drawing.PointF(5, 5)),
            6,
            [System.Drawing.Color]::FromArgb(251, 191, 36),
            [System.Drawing.Color]::FromArgb(78, 60, 10)
        )
        $e.Graphics.FillEllipse($gradRadial, 0, 0, 9, 9)
        $gradRadial.Dispose()
        
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(251, 191, 36), 1)
        $e.Graphics.DrawEllipse($pen, 0, 0, 9, 9)
        $pen.Dispose()
    })
    $pnlApp.Controls.Add($pnlBullet)

    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text      = $app.Nome
    $chk.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $chk.ForeColor = $corTexto
    $chk.BackColor = [System.Drawing.Color]::Transparent
    $chk.Location  = New-Object System.Drawing.Point(34, 12)
    $chk.Size      = New-Object System.Drawing.Size(280, 22)
    $chk.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $chk.add_CheckedChanged({
        Atualizar-ContadorInst
        $parentPnl = $this.Parent
        if ($this.Checked) {
            $this.ForeColor = $corVerdeLight
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

    $lblWingetId = New-Object System.Windows.Forms.Label
    $lblWingetId.Text      = $app.Winget
    $lblWingetId.Font      = New-Object System.Drawing.Font("Consolas", 7)
    $lblWingetId.ForeColor = [System.Drawing.Color]::FromArgb(50, 70, 60)
    $lblWingetId.Location  = New-Object System.Drawing.Point(324, 28)
    $lblWingetId.Size      = New-Object System.Drawing.Size(368, 12)
    $lblWingetId.BackColor = [System.Drawing.Color]::Transparent
    $pnlApp.Controls.Add($lblWingetId)

    $pnlBlocoIndiv.Controls.Add($pnlApp)
    $script:chksIndividuais += $chk
    $yChk += 44
}

$alturaBloco2 = 48 + ($appsIndividuais.Count * 44) + 14
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

# Botao instalar premium (dock bottom) com animação
$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text      = "  ▶ INSTALAR SELECIONADOS"
$btnInstalar.Dock      = "Bottom"
$btnInstalar.Height    = 54
$btnInstalar.BackColor = $corDestaque
$btnInstalar.ForeColor = [System.Drawing.Color]::FromArgb(8, 20, 14)
$btnInstalar.FlatStyle = "Flat"
$btnInstalar.FlatAppearance.BorderSize = 0
$btnInstalar.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnInstalar.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnInstalar.add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Gradiente sofisticado
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF($s.Width, 0)),
        [System.Drawing.Color]::FromArgb(52, 211, 153),
        [System.Drawing.Color]::FromArgb(16, 185, 129)
    )
    $e.Graphics.FillRectangle($grad, 0, 0, $s.Width, $s.Height)
    $grad.Dispose()
    
    # Brilho superior
    $penGlow = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 255, 255, 255), 1)
    $e.Graphics.DrawLine($penGlow, 0, 1, $s.Width, 1)
    $penGlow.Dispose()
    
    # Texto com shadow
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $fnt = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    
    # Shadow
    $e.Graphics.DrawString($s.Text, $fnt, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 0, 0, 0))), (New-Object System.Drawing.RectangleF(1, 1, $s.Width, $s.Height)), $sf)
    # Texto principal
    $e.Graphics.DrawString($s.Text, $fnt, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(8, 20, 14))), (New-Object System.Drawing.RectangleF(0, 0, $s.Width, $s.Height)), $sf)
    
    $fnt.Dispose(); $sf.Dispose()
})
$script:btnInstalar = $btnInstalar

$btnInstalar.add_Click({
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
                    Escrever-Log "$($p.Nome) pode ja estar instalado ou nao disponivel" "AVISO"
                }
            } catch {
                Escrever-Log "$($p.Nome) erro: $_" "ERRO"
            }
        }
        Escrever-Log "Instalacao concluida!" "OK"
    } -AoFinalizar {
        $script:btnInstalar.Enabled = $true
        $script:btnInstalar.Text    = "  ▶ INSTALAR SELECIONADOS"
    }
})

$pInst.Controls.Add($pnlPageHdr)
$pInst.Controls.Add($pnlInstScroll)

# ============================================================
#  ABA 1 - SISTEMA (placeholder)
# ============================================================
$pSys = $tabPanels[1]

$pnlSysHeader = New-Object System.Windows.Forms.Panel
$pnlSysHeader.Dock = "Top"
$pnlSysHeader.Height = 60
$pnlSysHeader.BackColor = $corPainelAlt

$lblSysTitle = New-Object System.Windows.Forms.Label
$lblSysTitle.Text = "⚙ Ferramentas de Sistema"
$lblSysTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblSysTitle.ForeColor = $corTextoClaro
$lblSysTitle.Location = New-Object System.Drawing.Point(18, 14)
$lblSysTitle.AutoSize = $true
$lblSysTitle.BackColor = [System.Drawing.Color]::Transparent

$pnlSysHeader.Controls.Add($lblSysTitle)
$pSys.Controls.Add($pnlSysHeader)

$lblSysContent = New-Object System.Windows.Forms.Label
$lblSysContent.Text = "Em desenvolvimento...`n`nFuncionalidades de sistema será adicionadas em breve."
$lblSysContent.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$lblSysContent.ForeColor = $corTextoMedio
$lblSysContent.Location = New-Object System.Drawing.Point(30, 100)
$lblSysContent.AutoSize = $true
$lblSysContent.BackColor = [System.Drawing.Color]::Transparent
$pSys.Controls.Add($lblSysContent)

# ============================================================
#  LOG TEXT BOX (Right Panel)
# ============================================================
$script:txtLog = New-Object System.Windows.Forms.RichTextBox
$script:txtLog.Location  = New-Object System.Drawing.Point(8, 48)
$script:txtLog.Size      = New-Object System.Drawing.Size(224, 614)
$script:txtLog.Anchor    = "Top,Left,Bottom,Right"
$script:txtLog.BackColor = $corFundo
$script:txtLog.ForeColor = $corDestaque
$script:txtLog.Font      = New-Object System.Drawing.Font("Consolas", 7)
$script:txtLog.ReadOnly  = $true
$script:txtLog.BorderStyle = "None"
$pnlLogOuter.Controls.Add($script:txtLog)

# Selecionar primeira aba
Selecionar-Tab -idx 0

# ============================================================
#  SHOW FORM
# ============================================================
$script:form.Add_Shown({ $script:form.Activate() })
$script:form.ShowDialog() | Out-Null
