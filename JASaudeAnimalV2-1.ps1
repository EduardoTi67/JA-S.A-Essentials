# ============================================================
#  JA Saude Animal - Ferramenta de TI
#  v2.0 - Totalmente Reformulada (Design & Estabilidade)
# ============================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Paleta de Cores Modernizada (Identidade Veterinaria/Saude) ---
$corFundo       = [System.Drawing.Color]::FromArgb(240, 244, 241)     # Cinza esverdeado bem claro
$corPainel      = [System.Drawing.Color]::FromArgb(255, 255, 255)     # Branco Puro (Cards)
$corBorda       = [System.Drawing.Color]::FromArgb(215, 225, 218)     # Borda sutil
$corDestaque    = [System.Drawing.Color]::FromArgb(34, 112, 73)       # Verde Saude Animal (Principal)
$corDestaqueHov = [System.Drawing.Color]::FromArgb(45, 145, 95)       # Verde Hover
$corAmarelo     = [System.Drawing.Color]::FromArgb(217, 131, 36)      # Alerta / Atencao
$corVermelho    = [System.Drawing.Color]::FromArgb(190, 49, 49)       # Perigo / Acoes Criticas
$corTexto       = [System.Drawing.Color]::FromArgb(40, 50, 45)        # Texto Escuro Principal
$corTextoClaro  = [System.Drawing.Color]::FromArgb(255, 255, 255)     # Texto Branco
$corTextoEscuro = [System.Drawing.Color]::FromArgb(110, 125, 115)     # Texto secundario (Mutado)
$corSidebar     = [System.Drawing.Color]::FromArgb(26, 48, 37)        # Verde Escuro Corporativo
$corSidebarHov  = [System.Drawing.Color]::FromArgb(38, 71, 55)        # Hover Sidebar
$corSidebarSel  = [System.Drawing.Color]::FromArgb(34, 112, 73)       # Selecionado Sidebar

# --- Componente Sincronizado para Log Sem Erros de Thread ---
$script:syncHash = [hashtable]::Synchronized(@{
    LogQueue = [System.Collections.Generic.Queue[string]]::new()
    BtnTexto = ""
    BtnStatus = $true
})

function Escrever-Log {
    param([string]$Msg, [string]$Tipo = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $linha = "[$ts] [$Tipo] $Msg"
    
    # Adiciona na fila sincronizada para que a UI consuma de forma segura
    $script:syncHash.LogQueue.Enqueue($linha)
}

function RegSet {
    param([string]$path, [string]$name, $value, [string]$type = "DWord")
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -ErrorAction SilentlyContinue
}

# --- Mecanismo Async Corrigido e Seguro ---
function Rodar-Async {
    param([ScriptBlock]$Bloco, [hashtable]$Vars = @{})
    
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions  = "ReuseThread"
    $rs.Open()
    
    foreach ($k in $Vars.Keys) { $rs.SessionStateProxy.SetVariable($k, $Vars[$k]) }
    $rs.SessionStateProxy.SetVariable("syncHash", $script:syncHash)
    
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    
    # Helpers basicos dentro do Runspace
    $ps.AddScript({
        function Inner-Log {
            param($m, $t="INFO")
            $ts = Get-Date -Format "HH:mm:ss"
            $syncHash.LogQueue.Enqueue("[$ts] [$t] $m")
        }
    }) | Out-Null
    
    $ps.AddScript($Bloco) | Out-Null
    $handle = $ps.BeginInvoke()
    
    # Monitor de finalizacao do Runspace
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 400
    $timer.add_Tick({
        if (-not $handle.IsCompleted) { return }
        $timer.Stop(); $timer.Dispose()
        try { $ps.EndInvoke($handle) } catch {}
        try { $ps.Dispose(); $rs.Close(); $rs.Dispose() } catch {}
    })
    $timer.Start()
}

function Criar-Icone {
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush($corDestaque)
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
$appsBasicos = @(
    @{ Nome="Firefox";                  Winget="Mozilla.Firefox" }
    @{ Nome="Google Chrome";            Winget="Google.Chrome" }
    @{ Nome="Microsoft Edge";           Winget="Microsoft.Edge" }
    @{ Nome="7-Zip";                    Winget="7zip.7zip" }
    @{ Nome="VC Redist x86/x64 Pack";   Winget="Microsoft.VCRedist.2015+.x64" }
    @{ Nome=".NET Desktop Runtime 8";   Winget="Microsoft.DotNet.DesktopRuntime.8" }
    @{ Nome=".NET Desktop Runtime 9";   Winget="Microsoft.DotNet.DesktopRuntime.9" }
    @{ Nome="OneDrive";                 Winget="Microsoft.OneDrive" }
    @{ Nome="Zoom";                     Winget="Zoom.Zoom" }
    @{ Nome="Microsoft Teams";          Winget="Microsoft.Teams" }
    @{ Nome="TeamViewer 15";            Winget="TeamViewer.TeamViewer" }
)

$appsIndividuais = @(
    @{ Nome="Adobe Acrobat Reader";        Winget="Adobe.Acrobat.Reader.64-bit";    Desc="Leitor PDF oficial Adobe (64-bit)" }
    @{ Nome="FortiClient VPN Only";        Winget="Fortinet.FortiClientVPN";       Desc="Cliente VPN Fortinet" }
    @{ Nome="Office 365 Setup";            Winget="Microsoft.Office";              Desc="Microsoft Office 365 Web Installer" }
    @{ Nome="PDF24 Creator";               Winget="geeksoftwareGmbH.PDF24Creator";  Desc="Criador e editor de PDF gratuito" }
    @{ Nome="Java 8 (JRE)";                Winget="Oracle.JavaRuntimeEnvironment";  Desc="Java Runtime Environment 8" }
    @{ Nome="VS Code";                     Winget="Microsoft.VisualStudioCode";     Desc="Editor de codigo Microsoft" }
    @{ Nome="VLC Media Player";            Winget="VideoLAN.VLC";                   Desc="Player de midia universal" }
)

# =================================================================
#  JANELA PRINCIPAL
# =================================================================
$script:form = New-Object System.Windows.Forms.Form
$script:form.Text          = "JA Saude Animal  |  Painel de Controle de TI"
$script:form.Size          = New-Object System.Drawing.Size(1180, 760)
$script:form.StartPosition = "CenterScreen"
$script:form.BackColor     = $corFundo
$script:form.ForeColor     = $corTexto
$script:form.Font          = New-Object System.Drawing.Font("Segoe UI", 9.5)
$script:form.MinimumSize   = New-Object System.Drawing.Size(1000, 680)
$script:form.Icon          = Criar-Icone

# Header Moderno
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock = "Top"; $pnlHeader.Height = 65; $pnlHeader.BackColor = $corPainel
$pnlHeader.Padding = New-Object System.Windows.Forms.Padding(20, 12, 20, 12)

$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text      = "JA SAÚDE ANIMAL"
$lblTitulo.Font      = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblTitulo.ForeColor = $corDestaque
$lblTitulo.Location  = New-Object System.Drawing.Point(20, 10)
$lblTitulo.AutoSize  = $true

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text      = "Suporte & Implantacao de Sistemas"
$lblSub.Font      = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblSub.ForeColor = $corTextoEscuro
$lblSub.Location  = New-Object System.Drawing.Point(24, 38)
$lblSub.AutoSize  = $true

$pnlHeader.Controls.AddRange(@($lblTitulo, $lblSub))
$script:form.Controls.Add($pnlHeader)

# Linha de divisao decorativa do Header
$pnlAccent = New-Object System.Windows.Forms.Panel
$pnlAccent.Dock = "Top"; $pnlAccent.Height = 2; $pnlAccent.BackColor = $corBorda
$script:form.Controls.Add($pnlAccent)

# Container Principal (Abaixo do Header)
$pnlMain = New-Object System.Windows.Forms.Panel
$pnlMain.Dock = "Fill"; $pnlMain.BackColor = $corFundo
$script:form.Controls.Add($pnlMain)

# Sidebar Lateral Esquerda
$pnlSidebar = New-Object System.Windows.Forms.Panel
$pnlSidebar.Dock = "Left"; $pnlSidebar.Width = 210; $pnlSidebar.BackColor = $corSidebar
$pnlMain.Controls.Add($pnlSidebar)

# Area Central de Conteudo
$pnlContent = New-Object System.Windows.Forms.Panel
$pnlContent.Dock = "Fill"; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(20)
$pnlMain.Controls.Add($pnlContent)

# Painel de Log Direita
$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.Dock = "Right"; $pnlLog.Width = 280; $pnlLog.BackColor = $corFundo
$pnlLog.Padding = New-Object System.Windows.Forms.Padding(10, 20, 20, 20)
$pnlMain.Controls.Add($pnlLog)

# =================================================================
#  GERENCIAMENTO DE TABS / ABAS
# =================================================================
$tabDefs = @(
    @{ Label="Instalar Programas"; Icon="  📥  " }
    @{ Label="Sistema e Reparos";  Icon="  🛠️  " }
)
$tabPanels  = [System.Collections.ArrayList]@()
$tabButtons = [System.Collections.ArrayList]@()

function Selecionar-Tab {
    param([int]$idx)
    for ($i = 0; $i -lt $tabPanels.Count; $i++) { $tabPanels[$i].Visible = ($i -eq $idx) }
    for ($i = 0; $i -lt $tabButtons.Count; $i++) {
        if ($i -eq $idx) {
            $tabButtons[$i].BackColor = $corSidebarSel
            $tabButtons[$i].ForeColor = $corTextoClaro
        } else {
            $tabButtons[$i].BackColor = $corSidebar
            $tabButtons[$i].ForeColor = $corTextoEscuro
        }
    }
}

$yBtn = 20
foreach ($def in $tabDefs) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = "$($def.Icon)$($def.Label)"
    $btn.Location  = New-Object System.Drawing.Point(0, $yBtn)
    $btn.Size      = New-Object System.Drawing.Size(210, 48)
    $btn.BackColor = $corSidebar
    $btn.ForeColor = $corTextoEscuro
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.FlatAppearance.MouseOverBackColor = $corSidebarHov
    $btn.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.TextAlign = "MiddleLeft"
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btn.Tag       = $tabButtons.Count
    
    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Dock = "Fill"; $pnl.Visible = $false; $pnl.BackColor = $corFundo
    $pnlContent.Controls.Add($pnl)
    
    $tabPanels.Add($pnl)  | Out-Null
    $tabButtons.Add($btn) | Out-Null
    $btn.add_Click({ Selecionar-Tab -idx $this.Tag })
    $pnlSidebar.Controls.Add($btn)
    $yBtn += 52
}

# Label de Creditos na Sidebar
$lblCredit = New-Object System.Windows.Forms.Label
$lblCredit.Text      = "JA Saude Animal - TI"
$lblCredit.ForeColor = $corTextoEscuro
$lblCredit.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblCredit.Dock      = "Bottom"
$lblCredit.Height    = 30
$lblCredit.TextAlign = "BottomLeft"
$lblCredit.Padding   = New-Object System.Windows.Forms.Padding(15,0,0,0)
$pnlSidebar.Controls.Add($lblCredit)

# =================================================================
#  ABA 0 - INSTALAR PROGRAMAS (INTERFACE & LOGICA)
# =================================================================
$pInst = $tabPanels[0]

$pnlInstScroll = New-Object System.Windows.Forms.Panel
$pnlInstScroll.Dock       = "Fill"
$pnlInstScroll.AutoScroll = $true

# Barra de Status da Selecao Superior
$pnlInstTop = New-Object System.Windows.Forms.Panel
$pnlInstTop.Dock      = "Top"
$pnlInstTop.Height    = 50
$pnlInstTop.BackColor = $corFundo

$lblContadorInst = New-Object System.Windows.Forms.Label
$lblContadorInst.Text      = "Nenhum aplicativo selecionado"
$lblContadorInst.ForeColor = $corTextoEscuro
$lblContadorInst.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblContadorInst.Location  = New-Object System.Drawing.Point(5, 12)
$lblContadorInst.AutoSize  = $true
$pnlInstTop.Controls.Add($lblContadorInst)

function Atualizar-ContadorInst {
    $total = 0
    if ($script:chkBasicos.Checked) { $total += $appsBasicos.Count }
    foreach ($chk in $script:chksIndividuais) { if ($chk.Checked) { $total++ } }
    
    if ($total -gt 0) {
        $lblContadorInst.Text = "$total item(ns) na fila de instalacao"
        $lblContadorInst.ForeColor = $corDestaque
    } else {
        $lblContadorInst.Text = "Nenhum aplicativo selecionado"
        $lblContadorInst.ForeColor = $corTextoEscuro
    }
}

$btnLimparInst = New-Object System.Windows.Forms.Button
$btnLimparInst.Text      = "Limpar Tudo"
$btnLimparInst.Location  = New-Object System.Drawing.Point(300, 8)
$btnLimparInst.Size      = New-Object System.Drawing.Size(110, 30)
$btnLimparInst.BackColor = $corPainel
$btnLimparInst.FlatStyle = "Flat"
$btnLimparInst.FlatAppearance.BorderColor = $corBorda
$btnLimparInst.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnLimparInst.add_Click({
    $script:chkBasicos.Checked = $false
    foreach ($chk in $script:chksIndividuais) { $chk.Checked = $false }
    Atualizar-ContadorInst
})
$pnlInstTop.Controls.Add($btnLimparInst)
$pInst.Controls.Add($pnlInstTop)

# --- CARD 1: PACOTE BASICO ---
$pnlBlocoBasico = New-Object System.Windows.Forms.Panel
$pnlBlocoBasico.Location  = New-Object System.Drawing.Point(0, 10)
$pnlBlocoBasico.Size      = New-Object System.Drawing.Size(620, 110)
$pnlBlocoBasico.Anchor    = "Top, Left, Right"
$pnlBlocoBasico.BackColor = $corPainel
$pnlBlocoBasico.BorderStyle = "None"

# Bordas finas simuladas por paineis
$bordaB = New-Object System.Windows.Forms.Panel; $bordaB.Dock = "Left"; $bordaB.Width = 4; $bordaB.BackColor = $corDestaque
$pnlBlocoBasico.Controls.Add($bordaB)

$lblBasicoTit = New-Object System.Windows.Forms.Label
$lblBasicoTit.Text      = "Kit Inicial Standard (Obrigatório em novas máquinas)"
$lblBasicoTit.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblBasicoTit.ForeColor = $corTexto
$lblBasicoTit.Location  = New-Object System.Drawing.Point(18, 14)
$lblBasicoTit.AutoSize  = $true

$lblBasicoDesc = New-Object System.Windows.Forms.Label
$lblBasicoDesc.Text      = "Instala em lote: Chrome, Firefox, Edge, 7-Zip, Runtimes .NET, VC++ Redist, Teams, Zoom e TeamViewer."
$lblBasicoDesc.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblBasicoDesc.ForeColor = $corTextoEscuro
$lblBasicoDesc.Location  = New-Object System.Drawing.Point(18, 38)
$lblBasicoDesc.Size      = New-Object System.Drawing.Size(580, 35)

$script:chkBasicos = New-Object System.Windows.Forms.CheckBox
$script:chkBasicos.Text      = "Selecionar todo o Kit Standard"
$script:chkBasicos.Font      = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$script:chkBasicos.ForeColor = $corDestaque
$script:chkBasicos.Location  = New-Object System.Drawing.Point(18, 75)
$script:chkBasicos.AutoSize  = $true
$script:chkBasicos.Cursor    = [System.Windows.Forms.Cursors]::Hand
$script:chkBasicos.add_CheckedChanged({ Atualizar-ContadorInst })

$pnlBlocoBasico.Controls.AddRange(@($lblBasicoTit, $lblBasicoDesc, $script:chkBasicos))
$pnlInstScroll.Controls.Add($pnlBlocoBasico)

# --- CARD 2: ADICIONAIS ---
$pnlBlocoIndiv = New-Object System.Windows.Forms.Panel
$pnlBlocoIndiv.Location  = New-Object System.Drawing.Point(0, 135)
$pnlBlocoIndiv.Size      = New-Object System.Drawing.Size(620, ($appsIndividuais.Count * 42 + 50))
$pnlBlocoIndiv.Anchor    = "Top, Left, Right"
$pnlBlocoIndiv.BackColor = $corPainel

$bordaI = New-Object System.Windows.Forms.Panel; $bordaI.Dock = "Left"; $bordaI.Width = 4; $bordaI.BackColor = $corBorda
$pnlBlocoIndiv.Controls.Add($bordaI)

$lblIndivTit = New-Object System.Windows.Forms.Label
$lblIndivTit.Text      = "Softwares Adicionais / Demandas Especificas"
$lblIndivTit.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblIndivTit.ForeColor = $corTexto
$lblIndivTit.Location  = New-Object System.Drawing.Point(18, 14)
$lblIndivTit.AutoSize  = $true
$pnlBlocoIndiv.Controls.Add($lblIndivTit)

$script:chksIndividuais = @()
$yChk = 48

foreach ($app in $appsIndividuais) {
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text      = $app.Nome
    $chk.Font      = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $chk.ForeColor = $corTexto
    $chk.Location  = New-Object System.Drawing.Point(18, $yChk)
    $chk.Size      = New-Object System.Drawing.Size(200, 24)
    $chk.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $chk.add_CheckedChanged({ Atualizar-ContadorInst })

    $lblDesc = New-Object System.Windows.Forms.Label
    $lblDesc.Text      = $app.Desc
    $lblDesc.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $lblDesc.ForeColor = $corTextoEscuro
    $lblDesc.Location  = New-Object System.Drawing.Point(230, ($yChk + 3))
    $lblDesc.Size      = New-Object System.Drawing.Size(370, 20)

    $pnlBlocoIndiv.Controls.AddRange(@($chk, $lblDesc))
    $script:chksIndividuais += $chk
    $yChk += 42
}
$pnlInstScroll.Controls.Add($pnlBlocoIndiv)
$pInst.Controls.Add($pnlInstScroll)

# Botao Rodar Instalacao (Fixo na parte inferior da aba)
$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text      = "🚀 Iniciar Instalacao dos Selecionados"
$btnInstalar.Dock      = "Bottom"
$btnInstalar.Height    = 50
$btnInstalar.BackColor = $corDestaque
$btnInstalar.ForeColor = $corTextoClaro
$btnInstalar.FlatStyle = "Flat"
$btnInstalar.FlatAppearance.BorderSize = 0
$btnInstalar.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnInstalar.Cursor    = [System.Windows.Forms.Cursors]::Hand
$script:btnInstalar    = $btnInstalar

$btnInstalar.add_Click({
    $listaFinal = [System.Collections.ArrayList]@()
    if ($script:chkBasicos.Checked) { foreach ($app in $appsBasicos) { $listaFinal.Add($app) | Out-Null } }
    for ($i = 0; $i -lt $script:chksIndividuais.Count; $i++) {
        if ($script:chksIndividuais[$i].Checked) { $listaFinal.Add($appsIndividuais[$i]) | Out-Null }
    }

    if ($listaFinal.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nenhum software foi marcado para instalacao.","Aviso","OK","Information") | Out-Null
        return
    }

    $script:btnInstalar.Enabled = $false
    $script:syncHash.BtnStatus = $false
    $script:syncHash.BtnTexto = "Instalando softwares..."

    # Execucao em lote totalmente corrigida isolada
    Rodar-Async -Vars @{Lista = $listaFinal} -Bloco {
        Inner-Log "=== INICIANDO IMPLANTACAO DE SOFTWARE ===" "INFO"
        $total = $Lista.Count
        $atual = 0

        foreach ($app in $Lista) {
            $atual++
            Inner-Log "[$atual/$total] Baixando/Instalando: $($app.Nome)..." "PROGRES"
            
            # Utilizacao do Start-Process com tratamento direto nativo do Engine
            $proc = Start-Process -FilePath "winget" -ArgumentList "install --id $($app.Winget) --silent --accept-package-agreements --accept-source-agreements --scope machine" -Wait -NoNewWindow -PassThru
            
            if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq -1978335189) {
                Inner-Log "$($app.Nome) instalado com sucesso!" "OK"
            } else {
                Inner-Log "Erro ou cancelado: $($app.Nome) (Cod: $($proc.ExitCode))" "ERRO"
            }
        }
        Inner-Log "=== PROCESSO CONCLUIDO ===" "OK"
        $syncHash.BtnStatus = $true
        $syncHash.BtnTexto = "🚀 Iniciar Instalacao dos Selecionados"
    }
})
$pInst.Controls.Add($btnInstalar)

# =================================================================
#  ABA 1 - SISTEMA E REPAROS (SFC, DISM, ETC)
# =================================================================
$pSis = $tabPanels[1]

$pnlSisScroll = New-Object System.Windows.Forms.Panel
$pnlSisScroll.Dock       = "Fill"
$pnlSisScroll.AutoScroll = $true

$sisAcoes = @(
    @{ Txt="Hardware Detalhado"; Desc="Gera informacoes tecnicas e detalhadas completas da máquina"; Cor=$corDestaque; Cmd="hwinfo" }
    @{ Txt="Limpeza de Disco";  Desc="Expurga pastas Temp, Prefetch, Log e caches ocultos de atualizacao"; Cor=$corDestaque; Cmd="limpeza" }
    @{ Txt="SFC Scannow";        Desc="Verifica integridade estrutural do Sistema Operacional"; Cor=$corAmarelo; Cmd="sfc" }
    @{ Txt="DISM Reparo";        Desc="Restaura a imagem base do Windows via Windows Update"; Cor=$corAmarelo; Cmd="dism" }
    @{ Txt="Checar Disco C:";    Desc="Agenda checagem fisica de setores corrompidos (Chkdsk)"; Cor=$corDestaque; Cmd="chkdsk" }
    @{ Txt="Flush Cache DNS";    Desc="Limpa tabelas de resolucao de nomes da rede local"; Cor=$corBorda; Cmd="dns" }
    @{ Txt="Reiniciar Explorer"; Desc="Recarrega a interface grafica padrão do Windows desktop"; Cor=$corBorda; Cmd="exp" }
    @{ Txt="Reiniciar PC";       Desc="Força o Reboot imediato da maquina de forma rapida"; Cor=$corVermelho; Cmd="reboot" }
)

$y = 10
foreach ($a in $sisAcoes) {
    $pnlRow = New-Object System.Windows.Forms.Panel
    $pnlRow.Location  = New-Object System.Drawing.Point(0, $y)
    $pnlRow.Size      = New-Object System.Drawing.Size(620, 56)
    $pnlRow.Anchor    = "Top, Left, Right"
    $pnlRow.BackColor = $corPainel

    $barRow = New-Object System.Windows.Forms.Panel
    $barRow.Dock = "Left"; $barRow.Width = 4; $barRow.BackColor = $a.Cor
    $pnlRow.Controls.Add($barRow)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = $a.Txt
    $btn.Location  = New-Object System.Drawing.Point(12, 10)
    $btn.Size      = New-Object System.Drawing.Size(160, 36)
    $btn.BackColor = if($a.Cor -eq $corBorda){ $corFundo } else { $a.Cor }
    $btn.ForeColor = if($a.Cor -eq $corBorda){ $corTexto } else { $corTextoClaro }
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.Tag       = $a.Cmd
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $a.Desc
    $lbl.Location  = New-Object System.Drawing.Point(185, 18)
    $lbl.Size      = New-Object System.Drawing.Size(420, 20)
    $lbl.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $lbl.ForeColor = $corTextoEscuro

    $btn.add_Click({
        switch ($this.Tag) {
            "hwinfo"  { Mostrar-HardwareInfo }
            "limpeza" {
                Escrever-Log "Iniciando faxina profunda no armazenamento do sistema..."
                $cmd = 'cmd /c "for %f in ("%TEMP%\*" "C:\Windows\Temp\*" "%APPDATA%\..\Local\Temp\*" "C:\Windows\Prefetch\*" "C:\Windows\SoftwareDistribution\Download\*") do del /f /q "%f" 2>nul & for /d %d in ("%TEMP%\*" "C:\Windows\Temp\*" "%APPDATA%\..\Local\CrashDumps\*") do rd /s /q "%d" 2>nul"'
                Start-Process "cmd.exe" -ArgumentList "/c $cmd" -WindowStyle Hidden -Wait
                Escrever-Log "Limpeza silenciosa executada com exito!" "OK"
            }
            "sfc"     { Escrever-Log "SFC disparado em nova janela de console."; Start-Process "cmd" -ArgumentList "/k sfc /scannow" -Verb RunAs }
            "dism"    { Escrever-Log "DISM Image Repair disparado."; Start-Process "cmd" -ArgumentList "/k DISM /Online /Cleanup-Image /RestoreHealth" -Verb RunAs }
            "chkdsk"  {
                $r = [System.Windows.Forms.MessageBox]::Show("Agendar varredura do Chkdsk C: para o proximo boot?","Confirmar","YesNo","Question")
                if ($r -eq "Yes") { echo "Y" | chkdsk C: /f /r | Out-Null; Escrever-Log "Agendamento do Chkdsk realizado!" "OK" }
            }
            "dns"     { ipconfig /flushdns | Out-Null; Escrever-Log "Cache DNS limpo localmente." "OK" }
            "exp"     { Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue; Start-Sleep 1; Start-Process "explorer"; Escrever-Log "Explorer Reiniciado." "OK" }
            "reboot"  { $r = [System.Windows.Forms.MessageBox]::Show("Deseja mesmo reiniciar o computador imediatamente?","Reiniciar","YesNo","Warning")
                        if ($r -eq "Yes") { Restart-Computer -Force } }
        }
    })

    $pnlRow.Controls.AddRange(@($btn, $lbl))
    $pnlSisScroll.Controls.Add($pnlRow)
    $y += 66
}
$pSis.Controls.Add($pnlSisScroll)

# =================================================================
#  PAINEL DE LOG (DIREITA) - CONSUMIDOR DE FILA SEGURO
# =================================================================
$lblLogTit = New-Object System.Windows.Forms.Label
$lblLogTit.Text      = "TERMINAL DE OPERAÇÕES"
$lblLogTit.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblLogTit.ForeColor = $corTextoEscuro
$lblLogTit.Location  = New-Object System.Drawing.Point(10, 0)
$lblLogTit.AutoSize  = $true
$pnlLog.Controls.Add($lblLogTit)

$script:txtLog = New-Object System.Windows.Forms.RichTextBox
$script:txtLog.Location    = New-Object System.Drawing.Point(10, 22)
$script:txtLog.Size        = New-Object System.Drawing.Size(260, 560)
$script:txtLog.Anchor      = "Top, Left, Bottom, Right"
$script:txtLog.BackColor   = [System.Drawing.Color]::FromArgb(28, 33, 30) # Dark Terminal
$script:txtLog.ForeColor   = [System.Drawing.Color]::FromArgb(140, 220, 170)
$script:txtLog.Font        = New-Object System.Drawing.Font("Consolas", 8.5)
$script:txtLog.ReadOnly    = $true
$script:txtLog.BorderStyle = "None"
$pnlLog.Controls.Add($script:txtLog)

$btnLimLog = New-Object System.Windows.Forms.Button
$btnLimLog.Text      = "Limpar Terminal"
$btnLimLog.Dock      = "Bottom"
$btnLimLog.Height    = 32
$btnLimLog.BackColor = $corPainel
$btnLimLog.FlatStyle = "Flat"
$btnLimLog.FlatAppearance.BorderColor = $corBorda
$btnLimLog.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnLimLog.add_Click({ $script:txtLog.Clear() })
$pnlLog.Controls.Add($btnLimLog)

# --- ENGINE DO TIMER DA UI PRINCIPAL ---
# Esse timer roda na Thread principal lendo a fila gerada em segundo plano de forma 100% segura.
$uiTimer = New-Object System.Windows.Forms.Timer
$uiTimer.Interval = 150
$uiTimer.add_Tick({
    # Consome os itens da fila de logs
    while ($script:syncHash.LogQueue.Count -gt 0) {
        $linha = $script:syncHash.LogQueue.Dequeue()
        if ($null -ne $linha) {
            $script:txtLog.AppendText("$linha`r`n")
            $script:txtLog.ScrollToCaret()
        }
    }
    
    # Atualiza dinamicamente o status do botao de instalacao
    if ($script:syncHash.BtnStatus -eq $false) {
        $script:btnInstalar.Enabled = $false
        if ($script:syncHash.BtnTexto -ne "") { $script:btnInstalar.Text = $script:syncHash.BtnTexto }
    } else {
        if ($script:btnInstalar.Enabled -eq $false) {
            $script:btnInstalar.Enabled = $true
            $script:btnInstalar.Text = "🚀 Iniciar Instalacao dos Selecionados"
            $script:chkBasicos.Checked = $false
            foreach ($chk in $script:chksIndividuais) { $chk.Checked = $false }
            Atualizar-ContadorInst
        }
    }
})
$uiTimer.Start()

# =================================================================
#  FUNÇÃO EXTRA: HARDWARE DETALHADO (VISUALIZADOR MODERNO)
# =================================================================
function Mostrar-HardwareInfo {
    Escrever-Log "Aguarde, extraindo mapa de barramentos e hardware..."
    
    $frmHW = New-Object System.Windows.Forms.Form
    $frmHW.Text          = "Especificacoes Detalhadas de Hardware"
    $frmHW.Size          = New-Object System.Drawing.Size(740, 600)
    $frmHW.StartPosition = "CenterParent"
    $frmHW.BackColor     = $corFundo
    $frmHW.Icon          = Criar-Icone
    
    $txtHW = New-Object System.Windows.Forms.RichTextBox
    $txtHW.Dock          = "Fill"
    $txtHW.BackColor     = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $txtHW.Font          = New-Object System.Drawing.Font("Consolas", 9.5)
    $txtHW.ReadOnly      = $true
    $txtHW.BorderStyle   = "None"
    
    # Coleta de dados simples e direta
    $cpu = (Get-CimInstance Win32_Processor).Name
    $mb  = (Get-CimInstance Win32_BaseBoard)
    $ram = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB, 1)
    $os  = (Get-CimInstance Win32_OperatingSystem).Caption
    
    $report = @(
        "=====================================================================",
        "           JA SAUDE ANIMAL - INVENTARIO DE HARDWARE LOCAL            ",
        "=====================================================================",
        "  Data de Emissao : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')",
        "  Estacao de TI   : $env:COMPUTERNAME",
        "  Usuario Logado  : $env:USERNAME",
        "---------------------------------------------------------------------",
        "  Sistema Operational : $os",
        "  Processador (CPU)   : $($cpu.Trim())",
        "  Placa-Mae Base      : $($mb.Manufacturer) $($mb.Product)",
        "  Memoria RAM Total   : $ram GB Disponiveis",
        "====================================================================="
    ) -join "`r`n"
    
    $txtHW.Text = $report
    $frmHW.Controls.Add($txtHW)
    $frmHW.ShowDialog() | Out-Null
}

# =================================================================
#  DISPARAR APLICACAO
# =================================================================
$script:form.add_Shown({
    Selecionar-Tab -idx 0
    Escrever-Log "Painel Administrativo JA Saude Animal iniciado." "OK"
    Escrever-Log "Modulo centralizado pronto para uso operacional." "INFO"
})

[System.Windows.Forms.Application]::Run($script:form)