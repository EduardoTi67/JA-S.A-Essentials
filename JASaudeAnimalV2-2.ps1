# ============================================================
#  JA Saude Animal - Ferramenta de TI (UX/UI Edition 2026)
#  Reestruturado com Flow Layouts e Proporcao Aurea
# ============================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Paleta de Cores Modernizada (Minimalismo Corporativo) ---
$cBgGlobal   = [System.Drawing.Color]::FromArgb(246, 248, 250) # Gelo sutil
$cBgCard     = [System.Drawing.Color]::FromArgb(255, 255, 255) # Branco puro
$cBrand      = [System.Drawing.Color]::FromArgb(35, 134, 85)   # Verde JA Saude Animal
$cBrandHov   = [System.Drawing.Color]::FromArgb(28, 107, 68)   # Verde Escuro (Hover)
$cTextDark   = [System.Drawing.Color]::FromArgb(31, 35, 40)    # Quase preto para leitura
$cTextMuted  = [System.Drawing.Color]::FromArgb(101, 109, 118) # Cinza para descricoes
$cBorder     = [System.Drawing.Color]::FromArgb(208, 215, 222) # Bordas sutis
$cTerminalBg = [System.Drawing.Color]::FromArgb(13, 17, 23)    # Fundo do Log (Modo Escuro)
$cTerminalTx = [System.Drawing.Color]::FromArgb(86, 211, 100)  # Texto do Log (Verde Hacker suave)
$cSidebarBg  = [System.Drawing.Color]::FromArgb(22, 27, 34)    # Sidebar escura

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

function RegSet {
    param([string]$path, [string]$name, $value, [string]$type = "DWord")
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -ErrorAction SilentlyContinue
}

function Rodar-Async {
    param([ScriptBlock]$Bloco, [hashtable]$Vars = @{}, [ScriptBlock]$AoFinalizar = $null)
    
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions  = "ReuseThread"
    $rs.Open()
    
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
# JANELA PRINCIPAL (Layout Base)
# =================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text          = "JA Saude Animal | Workstation Setup 2.0"
$form.Size          = New-Object System.Drawing.Size(1250, 760)
$form.StartPosition = "CenterScreen"
$form.BackColor     = $cBgGlobal
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 9.5)
$form.MinimumSize   = New-Object System.Drawing.Size(1024, 720)

# Hack 1: Header Topo
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock = "Top"; $pnlHeader.Height = 70; $pnlHeader.BackColor = $cBgCard
$pnlHeader.Padding = New-Object System.Windows.Forms.Padding(20, 15, 20, 15)

$lblBrand = New-Object System.Windows.Forms.Label
$lblBrand.Text = "JA SAÚDE ANIMAL"
$lblBrand.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblBrand.ForeColor = $cBrand
$lblBrand.Dock = "Left"
$lblBrand.AutoSize = $true

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "  |  Implantação & Reparos de TI"
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

# Corpo Principal
$pnlBody = New-Object System.Windows.Forms.Panel
$pnlBody.Dock = "Fill"
$form.Controls.Add($pnlBody)

# Hack 2: Hierarquia Estrita de Docking (Previne bugs de redimensionamento)
# Ordem de criacao: Esquerda -> Direita -> Centro(Fill)

# 1. Sidebar (Esquerda)
$pnlSidebar = New-Object System.Windows.Forms.Panel
$pnlSidebar.Dock = "Left"; $pnlSidebar.Width = 240; $pnlSidebar.BackColor = $cSidebarBg
$pnlSidebar.Padding = New-Object System.Windows.Forms.Padding(10, 20, 10, 20)
$pnlBody.Controls.Add($pnlSidebar)

# 2. Log / Terminal (Direita) - Proporcao Aurea
$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.Dock = "Right"; $pnlLog.Width = 320; $pnlLog.BackColor = $cBgGlobal
$pnlLog.Padding = New-Object System.Windows.Forms.Padding(15)
$pnlBody.Controls.Add($pnlLog)

# 3. Content (Centro)
$pnlContent = New-Object System.Windows.Forms.Panel
$pnlContent.Dock = "Fill"; $pnlContent.BackColor = $cBgGlobal
$pnlBody.Controls.Add($pnlContent)

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

$tabs = @( @{Name="📦 Instalação em Lote"}, @{Name="🛠️ Manutenção do Sistema"} )

# Flow Layout para os botoes da sidebar
$flowSidebar = New-Object System.Windows.Forms.FlowLayoutPanel
$flowSidebar.Dock = "Fill"
$flowSidebar.FlowDirection = "TopDown"
$flowSidebar.WrapContents = $false
$pnlSidebar.Controls.Add($flowSidebar)

foreach ($t in $tabs) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $t.Name
    $btn.Width = 220; $btn.Height = 50
    $btn.FlatStyle = "Flat"; $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.TextAlign = "MiddleLeft"
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Tag = $tabButtons.Count
    $btn.add_Click({ Selecionar-Tab $this.Tag })
    $flowSidebar.Controls.Add($btn)
    $tabButtons.Add($btn) | Out-Null
    
    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Dock = "Fill"; $pnl.Visible = $false
    # Hack 3: Usar Padding para dar "respiro" no conteudo principal
    $pnl.Padding = New-Object System.Windows.Forms.Padding(30) 
    $pnlContent.Controls.Add($pnl)
    $tabPanels.Add($pnl) | Out-Null
}

# =================================================================
# ABA 0: INSTALACAO (FlowLayoutPanel Magic)
# =================================================================
$abaInst = $tabPanels[0]

# Barra superior de acoes
$pnlInstTop = New-Object System.Windows.Forms.Panel
$pnlInstTop.Dock = "Top"; $pnlInstTop.Height = 40
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Nenhum aplicativo selecionado."
$lblStatus.Dock = "Left"; $lblStatus.AutoSize = $true
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblStatus.ForeColor = $cTextMuted

$btnLimpar = New-Object System.Windows.Forms.Button
$btnLimpar.Text = "Limpar Seleção"
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

# Container que vai organizar os cards sozinho
$flowInst = New-Object System.Windows.Forms.FlowLayoutPanel
$flowInst.Dock = "Fill"
$flowInst.FlowDirection = "TopDown"
$flowInst.WrapContents = $false
$flowInst.AutoScroll = $true
$flowInst.Padding = New-Object System.Windows.Forms.Padding(0, 15, 0, 15)
$abaInst.Controls.Add($flowInst)

# Atualizador UI
function Atualizar-Contador {
    $c = 0
    if ($script:chkBasicos.Checked) { $c += $appsBasicos.Count }
    foreach ($chk in $script:chkIndiv) { if ($chk.Checked) { $c++ } }
    
    $lblStatus.Text = if ($c -gt 0) { "$c item(ns) na fila de instalação" } else { "Nenhum aplicativo selecionado." }
    $lblStatus.ForeColor = if ($c -gt 0) { $cBrand } else { $cTextMuted }
    $script:btnInstalar.Enabled = ($c -gt 0)
}

# Hack 4: Criacao de Cards modernos via funcao
function Criar-CardBox($Titulo, $Desc, $Altura) {
    $card = New-Object System.Windows.Forms.Panel
    $card.Width = 600; $card.Height = $Altura
    $card.BackColor = $cBgCard
    $card.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 20)
    
    # Linha verde lateral
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

# --- Card 1: Pacote Base ---
$cardBase = Criar-CardBox "Kit Standard Corporativo" "Instala navegadores, compactador, Runtimes .NET, C++ Redist e ferramentas de comunicação (Teams, Zoom, TeamViewer) em lote." 140
$script:chkBasicos = New-Object System.Windows.Forms.CheckBox
$script:chkBasicos.Text = "Selecionar todos os aplicativos do Kit Standard"
$script:chkBasicos.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:chkBasicos.ForeColor = $cBrand
$script:chkBasicos.Location = New-Object System.Drawing.Point(20, 90); $script:chkBasicos.AutoSize = $true
$script:chkBasicos.Cursor = [System.Windows.Forms.Cursors]::Hand
$script:chkBasicos.add_CheckedChanged({ Atualizar-Contador })
$cardBase.Controls.Add($script:chkBasicos)
$flowInst.Controls.Add($cardBase)

# --- Card 2: Aplicativos Sob Demanda ---
$cardIndiv = Criar-CardBox "Softwares Específicos" "Marque apenas o que o usuário precisa:" ($appsIndividuais.Count * 35 + 90)
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
    $l.Location = New-Object System.Drawing.Point(220, $yP + 3); $l.Width = 350
    
    $cardIndiv.Controls.Add($c); $cardIndiv.Controls.Add($l)
    $script:chkIndiv += $c
    $yP += 35
}
$flowInst.Controls.Add($cardIndiv)

# Botao Final de Instalacao
$pnlFooterInst = New-Object System.Windows.Forms.Panel
$pnlFooterInst.Dock = "Bottom"; $pnlFooterInst.Height = 60
$script:btnInstalar = New-Object System.Windows.Forms.Button
$script:btnInstalar.Text = "Iniciar Instalação 🚀"
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
    $script:btnInstalar.Text = "Processando instalação..."
    
    Rodar-Async -Vars @{Lista = $lista} -Bloco {
        Escrever-Log "=== INICIANDO IMPLANTAÇÃO ===" "INFO"
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
        $script:btnInstalar.Text = "Iniciar Instalação 🚀"
        $script:chkBasicos.Checked = $false
        foreach ($c in $script:chkIndiv) { $c.Checked = $false }
        Atualizar-Contador
    }
})
$pnlFooterInst.Controls.Add($script:btnInstalar)
$abaInst.Controls.Add($pnlFooterInst)

# =================================================================
# ABA 1: SISTEMA E REPAROS (Grid Flow)
# =================================================================
$abaSis = $tabPanels[1]

$lblSisTop = New-Object System.Windows.Forms.Label
$lblSisTop.Text = "Ações Rápidas de Sistema"
$lblSisTop.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblSisTop.ForeColor = $cTextDark
$lblSisTop.Dock = "Top"; $lblSisTop.Height = 50
$abaSis.Controls.Add($lblSisTop)

$flowSis = New-Object System.Windows.Forms.FlowLayoutPanel
$flowSis.Dock = "Fill"
# Deixa fluir da esquerda pra direita, criando "linhas" automáticas
$flowSis.FlowDirection = "LeftToRight"
$flowSis.AutoScroll = $true
$abaSis.Controls.Add($flowSis)

$cmds = @(
    @{ Txt="Limpeza Profunda"; Desc="Expurga Temp, Prefetch e Logs"; Cmd="limp"; Cor=$cBrand }
    @{ Txt="Reparar SO (SFC)"; Desc="Verifica integridade do Windows"; Cmd="sfc"; Cor=[System.Drawing.Color]::Peru }
    @{ Txt="Restaurar Imagem"; Desc="DISM Online Cleanup"; Cmd="dism"; Cor=[System.Drawing.Color]::Peru }
    @{ Txt="Checar Disco"; Desc="Agenda Chkdsk para o boot"; Cmd="chk"; Cor=$cTextDark }
    @{ Txt="Flush DNS"; Desc="Renova tabelas locais de IP"; Cmd="dns"; Cor=$cTextDark }
    @{ Txt="Reiniciar Explorer"; Desc="Restaura interface gráfica"; Cmd="exp"; Cor=$cTextDark }
    @{ Txt="Reiniciar PC"; Desc="Reboot forçado da máquina"; Cmd="rb"; Cor=[System.Drawing.Color]::Firebrick }
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
    
    # Simulando um "titulo" dentro do botao mudando o texto via Paint
    $btn.Text = "$($c.Txt)`n`n$($c.Desc)"
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $btn.ForeColor = $cTextMuted
    
    # Barra de cor lateral no botao (HACK VISUAL)
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

# Hack 5: Timer que atualiza a interface sem quebrar threads
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
    Escrever-Log "JA Saúde Animal UI 2026 inicializado." "SYS"
    Escrever-Log "Operando sob: $env:USERNAME" "SYS"
})

$form.ShowDialog() | Out-Null
$uiTimer.Stop(); $uiTimer.Dispose()