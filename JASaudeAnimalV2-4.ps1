# ==============================================================================
#  JA Saúde Animal - Ferramenta de Suporte TI
#  v2.0 - Interface Profissional & Instalador Otimizado
#  Desenvolvido para JA Saúde Animal
# ==============================================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Paleta de Cores (Identidade Oficial JA Saúde Animal) ---
$corPrimaria     = [System.Drawing.Color]::FromArgb(21, 163, 82)   # Verde JA (Mountain Meadow)
$corSecundaria   = [System.Drawing.Color]::FromArgb(11, 69, 51)    # Verde Escuro (Bottle Green)
$corFundo        = [System.Drawing.Color]::FromArgb(242, 245, 243) # Off-white
$corPainel       = [System.Drawing.Color]::FromArgb(255, 255, 255) # Branco
$corBorda        = [System.Drawing.Color]::FromArgb(210, 225, 215)
$corTexto        = [System.Drawing.Color]::FromArgb(40, 60, 50)
$corTextoClaro   = [System.Drawing.Color]::FromArgb(255, 255, 255)
$corTextoEscuro  = [System.Drawing.Color]::FromArgb(100, 120, 110)
$corDestaque     = [System.Drawing.Color]::FromArgb(21, 163, 82)
$corPerigo       = [System.Drawing.Color]::FromArgb(200, 60, 60)

# --- Fontes ---
$fontPadrao      = New-Object System.Drawing.Font("Segoe UI", 9)
$fontTitulo      = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
$fontSubtitulo   = New-Object System.Drawing.Font("Segoe UI", 10)
$fontBotao       = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# --- Funções de Log ---
function Escrever-Log {
    param([string]$Msg, [string]$Tipo = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $linha = "[$ts] [$Tipo] $Msg"
    if ($script:txtLog -and !$script:txtLog.IsDisposed) {
        $script:txtLog.Invoke([System.Action]{
            $script:txtLog.AppendText("$linha`r`n")
            $script:txtLog.ScrollToCaret()
        }) | Out-Null
    }
}

# --- Funções de Sistema ---
function Executar-Limpeza {
    Escrever-Log "Iniciando limpeza de arquivos temporários..." "SISTEMA"
    $tempPaths = @("$env:TEMP\*", "C:\Windows\Temp\*", "C:\Windows\Prefetch\*")
    foreach ($path in $tempPaths) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
    Escrever-Log "Limpeza concluída." "OK"
}

# --- Runspace para Processamento Assíncrono ---
function Rodar-Async {
    param([ScriptBlock]$Bloco, [hashtable]$Vars = @{}, [ScriptBlock]$AoFinalizar = $null)
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"; $rs.Open()
    foreach ($k in $Vars.Keys) { $rs.SessionStateProxy.SetVariable($k, $Vars[$k]) }
    $fnLog = ${function:Escrever-Log}.ToString()
    $rs.SessionStateProxy.SetVariable("fnLog", $fnLog)
    $rs.SessionStateProxy.SetVariable("txtLogRef", $script:txtLog)
    $ps = [System.Management.Automation.PowerShell]::Create().AddScript("function Escrever-Log { $fnLog }; `$script:txtLog = `$txtLogRef").AddScript($Bloco)
    $ps.Runspace = $rs
    $handle = $ps.BeginInvoke()
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 500
    $timer.add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop(); $timer.Dispose()
            $ps.EndInvoke($handle); $ps.Dispose(); $rs.Close(); $rs.Dispose()
            if ($AoFinalizar) { & $AoFinalizar }
        }
    })
    $timer.Start()
}

# --- Definição de Apps ---
$apps = @(
    @{ Nome="Google Chrome"; ID="Google.Chrome" }
    @{ Nome="Mozilla Firefox"; ID="Mozilla.Firefox" }
    @{ Nome="7-Zip"; ID="7zip.7zip" }
    @{ Nome="Adobe Reader"; ID="Adobe.Acrobat.Reader.64-bit" }
    @{ Nome="AnyDesk"; ID="AnyDeskSoftwareGmbH.AnyDesk" }
    @{ Nome="TeamViewer"; ID="TeamViewer.TeamViewer" }
    @{ Nome="Office 365"; ID="Microsoft.Office" }
    @{ Nome="Zoom"; ID="Zoom.Zoom" }
    @{ Nome="Microsoft Teams"; ID="Microsoft.Teams" }
    @{ Nome="VLC Player"; ID="VideoLAN.VLC" }
)

# --- Interface Gráfica ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "JA Saúde Animal | Suporte TI"
$form.Size = New-Object System.Drawing.Size(900, 650)
$form.StartPosition = "CenterScreen"
$form.BackColor = $corFundo
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# Header
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock = "Top"; $pnlHeader.Height = 80; $pnlHeader.BackColor = $corPainel
$lblTit = New-Object System.Windows.Forms.Label
$lblTit.Text = "JA SAÚDE ANIMAL"; $lblTit.Font = $fontTitulo; $lblTit.ForeColor = $corPrimaria
$lblTit.Location = New-Object System.Drawing.Point(20, 15); $lblTit.AutoSize = $true
$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Ferramenta de Manutenção e Instalação"; $lblSub.Font = $fontSubtitulo; $lblSub.ForeColor = $corTextoEscuro
$lblSub.Location = New-Object System.Drawing.Point(22, 45); $lblSub.AutoSize = $true
$pnlHeader.Controls.AddRange(@($lblTit, $lblSub))

# Sidebar
$pnlSide = New-Object System.Windows.Forms.Panel
$pnlSide.Dock = "Left"; $pnlSide.Width = 180; $pnlSide.BackColor = $corSecundaria

# Content Area
$pnlMain = New-Object System.Windows.Forms.Panel
$pnlMain.Dock = "Fill"; $pnlMain.Padding = New-Object System.Windows.Forms.Padding(20)

# Log Panel (Bottom)
$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.Dock = "Bottom"; $pnlLog.Height = 150; $pnlLog.BackColor = [System.Drawing.Color]::Black
$script:txtLog = New-Object System.Windows.Forms.TextBox
$script:txtLog.Multiline = $true; $script:txtLog.ReadOnly = $true; $script:txtLog.Dock = "Fill"
$script:txtLog.BackColor = [System.Drawing.Color]::Black; $script:txtLog.ForeColor = [System.Drawing.Color]::LightGreen
$script:txtLog.Font = New-Object System.Drawing.Font("Consolas", 8); $script:txtLog.ScrollBars = "Vertical"
$pnlLog.Controls.Add($script:txtLog)

# --- Abas (Simuladas por Painéis) ---
$pnlInstalador = New-Object System.Windows.Forms.Panel
$pnlInstalador.Dock = "Fill"; $pnlInstalador.Visible = $true

$flowApps = New-Object System.Windows.Forms.FlowLayoutPanel
$flowApps.Dock = "Fill"; $flowApps.AutoScroll = $true; $flowApps.BackColor = $corPainel
$script:chks = @()
foreach ($a in $apps) {
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text = $a.Nome; $c.Tag = $a.ID; $c.Width = 180; $c.Margin = New-Object System.Windows.Forms.Padding(10)
    $flowApps.Controls.Add($c); $script:chks += $c
}

$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text = "INSTALAR SELECIONADOS"; $btnInstalar.Dock = "Bottom"; $btnInstalar.Height = 50
$btnInstalar.BackColor = $corPrimaria; $btnInstalar.ForeColor = $corTextoClaro; $btnInstalar.FlatStyle = "Flat"
$btnInstalar.Font = $fontBotao; $btnInstalar.Cursor = [System.Windows.Forms.Cursors]::Hand

$btnInstalar.add_Click({
    $sel = $script:chks | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Selecione um app.", "Aviso"); return }
    $btnInstalar.Enabled = $false
    Rodar-Async -Vars @{ids = $sel.Tag} -Bloco {
        Escrever-Log "=== Iniciando Instalação ===" "INFO"
        foreach ($id in $ids) {
            Escrever-Log "Processando: $id..." "INFO"
            # O SEGREDO DO WINGET: --accept-source-agreements evita o travamento
            $p = Start-Process winget -ArgumentList "install --id $id --silent --accept-package-agreements --accept-source-agreements" -Wait -PassThru -NoNewWindow
            if ($p.ExitCode -eq 0 -or $p.ExitCode -eq -1978335189) { Escrever-Log "Sucesso: $id" "OK" }
            else { Escrever-Log "Erro em $id (Cod: $($p.ExitCode))" "ERRO" }
        }
        Escrever-Log "=== Finalizado ===" "OK"
    } -AoFinalizar { $btnInstalar.Enabled = $true; [System.Windows.Forms.MessageBox]::Show("Concluído!", "TI JA") }
})

$pnlInstalador.Controls.AddRange(@($flowApps, $btnInstalar))

# --- Aba Sistema ---
$pnlSistema = New-Object System.Windows.Forms.Panel
$pnlSistema.Dock = "Fill"; $pnlSistema.Visible = $false

$flowSist = New-Object System.Windows.Forms.FlowLayoutPanel
$flowSist.Dock = "Fill"; $flowSist.BackColor = $corPainel

function Add-SistBtn {
    param($Txt, $Script)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Txt; $b.Width = 320; $b.Height = 45; $b.Margin = New-Object System.Windows.Forms.Padding(10)
    $b.FlatStyle = "Flat"; $b.BackColor = $corFundo; $b.Font = $fontPadrao
    $b.add_Click($Script)
    $flowSist.Controls.Add($b)
}

Add-SistBtn "Limpeza de Arquivos Temporários" { Executar-Limpeza }
Add-SistBtn "Reparar Sistema (SFC /Scannow)" { 
    Escrever-Log "Iniciando SFC..." "SISTEMA"
    Rodar-Async -Bloco { sfc /scannow } -AoFinalizar { Escrever-Log "SFC Concluído." "OK" }
}
Add-SistBtn "Otimizar Imagem (DISM)" { 
    Escrever-Log "Iniciando DISM..." "SISTEMA"
    Rodar-Async -Bloco { dism /online /cleanup-image /restorehealth } -AoFinalizar { Escrever-Log "DISM Concluído." "OK" }
}
Add-SistBtn "Flush DNS" { 
    ipconfig /flushdns | Out-Null
    Escrever-Log "Cache DNS limpo." "OK"
}
Add-SistBtn "Reiniciar Explorer" { 
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer
    Escrever-Log "Explorer reiniciado." "OK"
}

$pnlSistema.Controls.Add($flowSist)

# --- Navegação Sidebar ---
function Set-Tab {
    param($Name)
    $pnlInstalador.Visible = ($Name -eq "INST")
    $pnlSistema.Visible = ($Name -eq "SIST")
}

$btnNavInst = New-Object System.Windows.Forms.Button
$btnNavInst.Text = "INSTALADOR"; $btnNavInst.Dock = "Top"; $btnNavInst.Height = 60
$btnNavInst.FlatStyle = "Flat"; $btnNavInst.ForeColor = $corTextoClaro; $btnNavInst.FlatAppearance.BorderSize = 0
$btnNavInst.add_Click({ Set-Tab "INST" })

$btnNavSist = New-Object System.Windows.Forms.Button
$btnNavSist.Text = "SISTEMA"; $btnNavSist.Dock = "Top"; $btnNavSist.Height = 60
$btnNavSist.FlatStyle = "Flat"; $btnNavSist.ForeColor = $corTextoClaro; $btnNavSist.FlatAppearance.BorderSize = 0
$btnNavSist.add_Click({ Set-Tab "SIST" })

$pnlSide.Controls.AddRange(@($btnNavSist, $btnNavInst))
$pnlMain.Controls.AddRange(@($pnlInstalador, $pnlSistema))

$form.Controls.AddRange(@($pnlMain, $pnlLog, $pnlSide, $pnlHeader))
$form.ShowDialog() | Out-Null
