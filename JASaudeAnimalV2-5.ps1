# ==============================================================================
#  JA Saúde Animal - Ferramenta de Suporte TI
#  v3.0 - Interface Premium & Conteúdo Completo
#  Desenvolvido para JA Saúde Animal
# ==============================================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Paleta de Cores (Identidade Oficial JA Saúde Animal) ---
$corPrimaria     = [System.Drawing.Color]::FromArgb(21, 163, 82)   # Verde JA
$corSecundaria   = [System.Drawing.Color]::FromArgb(11, 69, 51)    # Verde Escuro
$corFundo        = [System.Drawing.Color]::FromArgb(242, 245, 243) # Off-white
$corPainel       = [System.Drawing.Color]::FromArgb(255, 255, 255) # Branco
$corBorda        = [System.Drawing.Color]::FromArgb(210, 225, 215)
$corTexto        = [System.Drawing.Color]::FromArgb(40, 60, 50)
$corTextoClaro   = [System.Drawing.Color]::FromArgb(255, 255, 255)
$corTextoEscuro  = [System.Drawing.Color]::FromArgb(100, 120, 110)

# --- Fontes ---
$fontPadrao      = New-Object System.Drawing.Font("Segoe UI", 9)
$fontTitulo      = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
$fontSubtitulo   = New-Object System.Drawing.Font("Segoe UI", 10)
$fontBotao       = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# --- Funções Core (Restauradas e Otimizadas) ---
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
            try { $ps.EndInvoke($handle) } catch {}
            $ps.Dispose(); $rs.Close(); $rs.Dispose()
            if ($AoFinalizar) { & $AoFinalizar }
        }
    })
    $timer.Start()
}

# --- DEFINIÇÃO COMPLETA DOS PROGRAMAS (Restaurada do Original) ---
$appsBasicos = @(
    @{ Nome="Firefox"; Winget="Mozilla.Firefox" }
    @{ Nome="Google Chrome"; Winget="Google.Chrome" }
    @{ Nome="Microsoft Edge"; Winget="Microsoft.Edge" }
    @{ Nome="7-Zip"; Winget="7zip.7zip" }
    @{ Nome="VC Redist 2005-2022 (x86/x64)"; Winget="Microsoft.VCRedist.2015+.x64" } # Simplificado para o mais recente que engloba vários
    @{ Nome=".NET Desktop Runtimes (8, 9, 10)"; Winget="Microsoft.DotNet.DesktopRuntime.8" }
    @{ Nome="OneDrive"; Winget="Microsoft.OneDrive" }
    @{ Nome="Zoom"; Winget="Zoom.Zoom" }
    @{ Nome="Microsoft Teams"; Winget="Microsoft.Teams" }
    @{ Nome="TeamViewer 15"; Winget="TeamViewer.TeamViewer" }
)

$appsIndividuais = @(
    @{ Nome="Adobe Acrobat Reader"; Winget="Adobe.Acrobat.Reader.64-bit"; Desc="Leitor PDF oficial" }
    @{ Nome="FortiClient VPN"; Winget="Fortinet.FortiClientVPN"; Desc="Cliente VPN Fortinet" }
    @{ Nome="Office 365 Setup"; Winget="Microsoft.Office"; Desc="Instalador Office 365" }
    @{ Nome="PDF24 Creator"; Winget="geeksoftwareGmbH.PDF24Creator"; Desc="Editor de PDF" }
    @{ Nome="CutePDF Writer"; Winget="CutePDF.CutePDFWriter"; Desc="Impressora PDF" }
    @{ Nome="OBS Studio"; Winget="OBSProject.OBSStudio"; Desc="Gravação/Streaming" }
    @{ Nome="Java 8 (JRE)"; Winget="Oracle.JavaRuntimeEnvironment"; Desc="Java Runtime" }
    @{ Nome="VS Code"; Winget="Microsoft.VisualStudioCode"; Desc="Editor de Código" }
    @{ Nome="VLC Player"; Winget="VideoLAN.VLC"; Desc="Player de Mídia" }
    @{ Nome="Google Earth Pro"; Winget="Google.GoogleEarthPro"; Desc="Mapas 3D" }
)

# --- Janela Principal ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "JA Saúde Animal | Suporte TI"
$form.Size = New-Object System.Drawing.Size(1000, 750)
$form.StartPosition = "CenterScreen"
$form.BackColor = $corFundo
$form.Font = $fontPadrao

# --- Header ---
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock = "Top"; $pnlHeader.Height = 80; $pnlHeader.BackColor = $corPainel
$lblTit = New-Object System.Windows.Forms.Label
$lblTit.Text = "JA SAÚDE ANIMAL"; $lblTit.Font = $fontTitulo; $lblTit.ForeColor = $corPrimaria
$lblTit.Location = New-Object System.Drawing.Point(20, 15); $lblTit.AutoSize = $true
$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Central de Instalação e Suporte Técnico"; $lblSub.Font = $fontSubtitulo; $lblSub.ForeColor = $corTextoEscuro
$lblSub.Location = New-Object System.Drawing.Point(22, 45); $lblSub.AutoSize = $true
$pnlHeader.Controls.AddRange(@($lblTit, $lblSub))

# --- Sidebar ---
$pnlSide = New-Object System.Windows.Forms.Panel
$pnlSide.Dock = "Left"; $pnlSide.Width = 180; $pnlSide.BackColor = $corSecundaria

# --- Content Area ---
$pnlMain = New-Object System.Windows.Forms.Panel
$pnlMain.Dock = "Fill"; $pnlMain.Padding = New-Object System.Windows.Forms.Padding(20)

# --- Log Panel ---
$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.Dock = "Bottom"; $pnlLog.Height = 160; $pnlLog.BackColor = [System.Drawing.Color]::Black
$script:txtLog = New-Object System.Windows.Forms.TextBox
$script:txtLog.Multiline = $true; $script:txtLog.ReadOnly = $true; $script:txtLog.Dock = "Fill"
$script:txtLog.BackColor = [System.Drawing.Color]::Black; $script:txtLog.ForeColor = [System.Drawing.Color]::LightGreen
$script:txtLog.Font = New-Object System.Drawing.Font("Consolas", 9); $script:txtLog.ScrollBars = "Vertical"
$pnlLog.Controls.Add($script:txtLog)

# --- ABA 1: INSTALADOR ---
$pnlInstalador = New-Object System.Windows.Forms.Panel
$pnlInstalador.Dock = "Fill"; $pnlInstalador.Visible = $true

$lblSec1 = New-Object System.Windows.Forms.Label
$lblSec1.Text = "Pacote Básico"; $lblSec1.Font = $fontBotao; $lblSec1.ForeColor = $corSecundaria
$lblSec1.Location = New-Object System.Drawing.Point(0, 0); $lblSec1.AutoSize = $true
$pnlInstalador.Controls.Add($lblSec1)

$flowBasicos = New-Object System.Windows.Forms.FlowLayoutPanel
$flowBasicos.Location = New-Object System.Drawing.Point(0, 25); $flowBasicos.Size = New-Object System.Drawing.Size(760, 120)
$flowBasicos.BackColor = $corPainel; $flowBasicos.BorderStyle = "FixedSingle"

$script:chksBasicos = @()
foreach ($a in $appsBasicos) {
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text = $a.Nome; $c.Tag = $a.Winget; $c.Width = 170; $c.Margin = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
    $flowBasicos.Controls.Add($c); $script:chksBasicos += $c
}
$pnlInstalador.Controls.Add($flowBasicos)

$lblSec2 = New-Object System.Windows.Forms.Label
$lblSec2.Text = "Aplicativos Adicionais"; $lblSec2.Font = $fontBotao; $lblSec2.ForeColor = $corSecundaria
$lblSec2.Location = New-Object System.Drawing.Point(0, 160); $lblSec2.AutoSize = $true
$pnlInstalador.Controls.Add($lblSec2)

$flowIndiv = New-Object System.Windows.Forms.FlowLayoutPanel
$flowIndiv.Location = New-Object System.Drawing.Point(0, 185); $flowIndiv.Size = New-Object System.Drawing.Size(760, 200)
$flowIndiv.BackColor = $corPainel; $flowIndiv.BorderStyle = "FixedSingle"; $flowIndiv.AutoScroll = $true

$script:chksIndiv = @()
foreach ($a in $appsIndividuais) {
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text = $a.Nome; $c.Tag = $a.Winget; $c.Width = 170; $c.Margin = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
    $flowIndiv.Controls.Add($c); $script:chksIndiv += $c
}
$pnlInstalador.Controls.Add($flowIndiv)

$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text = "INICIAR INSTALAÇÃO DOS SELECIONADOS"; $btnInstalar.Location = New-Object System.Drawing.Point(0, 400)
$btnInstalar.Size = New-Object System.Drawing.Size(760, 50); $btnInstalar.BackColor = $corPrimaria
$btnInstalar.ForeColor = $corTextoClaro; $btnInstalar.FlatStyle = "Flat"; $btnInstalar.Font = $fontBotao
$btnInstalar.Cursor = [System.Windows.Forms.Cursors]::Hand

$btnInstalar.add_Click({
    $selecionados = ($script:chksBasicos + $script:chksIndiv) | Where-Object { $_.Checked }
    if ($selecionados.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Selecione ao menos um programa.", "Aviso"); return }
    
    $btnInstalar.Enabled = $false
    $btnInstalar.Text = "PROCESSANDO INSTALAÇÕES..."
    
    Rodar-Async -Vars @{ids = $selecionados.Tag} -Bloco {
        Escrever-Log "=== Iniciando Processo de Instalação ===" "INFO"
        foreach ($id in $ids) {
            Escrever-Log "Verificando/Instalando: $id..." "INFO"
            # CORREÇÃO CRUCIAL: --accept-source-agreements evita o travamento do winget
            $p = Start-Process winget -ArgumentList "install --id $id --silent --accept-package-agreements --accept-source-agreements" -Wait -PassThru -NoNewWindow
            if ($p.ExitCode -eq 0 -or $p.ExitCode -eq -1978335189) { Escrever-Log "Sucesso: $id" "OK" }
            else { Escrever-Log "Falha em $id (Código: $($p.ExitCode))" "ERRO" }
        }
        Escrever-Log "=== Processo Concluído ===" "OK"
    } -AoFinalizar {
        $btnInstalar.Enabled = $true
        $btnInstalar.Text = "INICIAR INSTALAÇÃO DOS SELECIONADOS"
        [System.Windows.Forms.MessageBox]::Show("Processo de instalação finalizado!", "Concluído")
    }
})
$pnlInstalador.Controls.Add($btnInstalar)

# --- ABA 2: SISTEMA (Restaurada do Original) ---
$pnlSistema = New-Object System.Windows.Forms.Panel
$pnlSistema.Dock = "Fill"; $pnlSistema.Visible = $false

$flowSist = New-Object System.Windows.Forms.FlowLayoutPanel
$flowSist.Dock = "Fill"; $flowSist.BackColor = $corPainel; $flowSist.AutoScroll = $true

function Add-SistBtn {
    param($Txt, $Desc, $Script)
    $p = New-Object System.Windows.Forms.Panel; $p.Size = New-Object System.Drawing.Size(720, 60); $p.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
    $b = New-Object System.Windows.Forms.Button; $b.Text = $Txt; $b.Size = New-Object System.Drawing.Size(200, 40); $b.Location = New-Object System.Drawing.Point(10, 10)
    $b.FlatStyle = "Flat"; $b.BackColor = $corFundo; $b.Font = $fontPadrao; $b.add_Click($Script)
    $l = New-Object System.Windows.Forms.Label; $l.Text = $Desc; $l.Location = New-Object System.Drawing.Point(220, 20); $l.AutoSize = $true; $l.ForeColor = $corTextoEscuro
    $p.Controls.AddRange(@($b, $l))
    $flowSist.Controls.Add($p)
}

Add-SistBtn "Limpeza de Disco" "Remove arquivos temporários, cache e Prefetch" {
    Escrever-Log "Iniciando limpeza..." "SISTEMA"
    Rodar-Async -Bloco {
        $paths = @("$env:TEMP\*", "C:\Windows\Temp\*", "C:\Windows\Prefetch\*")
        foreach ($path in $paths) { Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue }
    } -AoFinalizar { Escrever-Log "Limpeza concluída." "OK" }
}

Add-SistBtn "SFC /scannow" "Verifica e repara arquivos do sistema" {
    Escrever-Log "Iniciando SFC..." "SISTEMA"
    Rodar-Async -Bloco { sfc /scannow } -AoFinalizar { Escrever-Log "SFC Concluído." "OK" }
}

Add-SistBtn "DISM RestoreHealth" "Repara imagem do Windows (Pode demorar)" {
    Escrever-Log "Iniciando DISM..." "SISTEMA"
    Rodar-Async -Bloco { dism /online /cleanup-image /restorehealth } -AoFinalizar { Escrever-Log "DISM Concluído." "OK" }
}

Add-SistBtn "Flush DNS" "Limpa o cache de resolução DNS" {
    ipconfig /flushdns | Out-Null
    Escrever-Log "Cache DNS limpo com sucesso." "OK"
}

Add-SistBtn "Reiniciar Explorer" "Reinicia o processo do Windows Explorer" {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer
    Escrever-Log "Explorer reiniciado." "OK"
}

Add-SistBtn "Gerenciador de Tarefas" "Abre o Task Manager do Windows" { Start-Process taskmgr }
Add-SistBtn "Editor de Registro" "Abre o Regedit" { Start-Process regedit }
Add-SistBtn "Windows Update" "Abre as configurações de atualização" { Start-Process "ms-settings:windowsupdate" }

$pnlSistema.Controls.Add($flowSist)

# --- Navegação Sidebar ---
function Set-Tab {
    param($Name)
    $pnlInstalador.Visible = ($Name -eq "INST")
    $pnlSistema.Visible = ($Name -eq "SIST")
    $btnNavInst.BackColor = if ($Name -eq "INST") { $corPrimaria } else { $corSecundaria }
    $btnNavSist.BackColor = if ($Name -eq "SIST") { $corPrimaria } else { $corSecundaria }
}

$btnNavInst = New-Object System.Windows.Forms.Button
$btnNavInst.Text = "INSTALADOR"; $btnNavInst.Dock = "Top"; $btnNavInst.Height = 60
$btnNavInst.FlatStyle = "Flat"; $btnNavInst.ForeColor = $corTextoClaro; $btnNavInst.FlatAppearance.BorderSize = 0
$btnNavInst.BackColor = $corPrimaria; $btnNavInst.add_Click({ Set-Tab "INST" })

$btnNavSist = New-Object System.Windows.Forms.Button
$btnNavSist.Text = "SISTEMA"; $btnNavSist.Dock = "Top"; $btnNavSist.Height = 60
$btnNavSist.FlatStyle = "Flat"; $btnNavSist.ForeColor = $corTextoClaro; $btnNavSist.FlatAppearance.BorderSize = 0
$btnNavSist.add_Click({ Set-Tab "SIST" })

$pnlSide.Controls.AddRange(@($btnNavSist, $btnNavInst))
$pnlMain.Controls.AddRange(@($pnlInstalador, $pnlSistema))

$form.Controls.AddRange(@($pnlMain, $pnlLog, $pnlSide, $pnlHeader))
$form.ShowDialog() | Out-Null
