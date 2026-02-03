# 🚀 DARPA HUB v7.5 - ULTIMATE EDITION

## 📋 Visão Geral

**DARPA HUB** é um **script hub premium completo** para Roblox com interface moderna e módulos de nível profissional. Inspirado no AirHub mas com visual e funcionalidades melhoradas.

### ✨ Módulos Incluídos

- ✅ **Aimbot Completo** - FOV Circle, Prediction, Smoothing, Third Person
- ✅ **ESP Premium** - Boxes 2D/3D, Tracers, Names, Distance, Health
- ✅ **Wall Hack** - Chams (highlight), Visibility Check
- ✅ **Health Bars** - 4 posições (Left, Right, Top, Bottom)
- ✅ **Head Dots** - Marcador na cabeça dos players
- ✅ **Crosshair Customizado** - Totalmente configurável
- ✅ **Player Enhancements** - WalkSpeed, JumpPower, FOV, Infinite Jump, No Clip
- ✅ **Performance Monitor** - FPS, Ping, Memória em tempo real
- ✅ **Utilities** - Fullbright, Anti-AFK, Chat Spammer
- ✅ **Hook System** - Sistema completo de hooks para extensibilidade
- ✅ **UI Premium** - Interface moderna com animações suaves

---

## 🎯 Instalação Rápida

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/seu-repo/DarpaHub_Complete.lua"))()
```

---

## 📚 Documentação dos Módulos

### 🎯 AIMBOT MODULE

#### Configurações Principais

```lua
AimbotModule.Settings = {
    Enabled = false,                 -- Ativar aimbot
    TeamCheck = false,               -- Não mirar em teammates
    AliveCheck = true,               -- Só mirar em players vivos
    WallCheck = false,               -- Não mirar através de paredes
    VisibleCheck = true,             -- Só mirar em players visíveis
    
    -- Targeting
    TargetPart = "Head",             -- Parte para mirar
    Priority = "Distance",           -- Distance, Health, Crosshair
    
    -- Smoothing
    Smoothing = 0.15,                -- Suavização (0 = instantâneo)
    PredictionEnabled = false,       -- Prever movimento
    PredictionAmount = 0.12,         -- Quantidade de predição
    
    -- Third Person
    ThirdPerson = false,             -- Suporte para terceira pessoa
    ThirdPersonSensitivity = 3,      -- Sensibilidade em terceira pessoa
    
    -- Keybind
    TriggerKey = Enum.UserInputType.MouseButton2,  -- Tecla para ativar
    ToggleMode = false,              -- Toggle ou hold
    
    -- Sticky
    StickyLock = true,               -- Manter lock mesmo fora do FOV
    StickyAim = false,               -- Lock automático sem segurar tecla
}
```

#### FOV Circle

```lua
AimbotModule.FOV = {
    Enabled = true,                  -- Ativar FOV
    Visible = true,                  -- Mostrar círculo
    Radius = 150,                    -- Raio do círculo
    Color = Color3.fromRGB(255, 255, 255),        -- Cor normal
    LockedColor = Color3.fromRGB(255, 50, 50),    -- Cor quando travado
    Transparency = 0.5,              -- Transparência
    Filled = false,                  -- Preenchido
    Thickness = 2,                   -- Espessura
    Sides = 64,                      -- Lados do círculo
}
```

#### Métodos

```lua
AimbotModule:Init()              -- Inicializar módulo
AimbotModule:Disable()           -- Desativar módulo
AimbotModule:GetLockedTarget()   -- Obter alvo atual
AimbotModule:ForceUnlock()       -- Destravar do alvo
AimbotModule:IsRunning()         -- Verificar se está ativo
```

#### Exemplo de Uso

```lua
-- Carregar módulo
local Aimbot = loadstring(game:HttpGet("URL"))()
Aimbot:Init()

-- Configurar
Aimbot.Settings.Enabled = true
Aimbot.Settings.TargetPart = "Head"
Aimbot.Settings.Smoothing = 0.2
Aimbot.FOV.Radius = 200

-- Verificar alvo
if Aimbot:IsRunning() then
    local target = Aimbot:GetLockedTarget()
    if target then
        print("Travado em:", target.Name)
    end
end
```

---

### 👁️ ESP/WALL HACK MODULE

#### Configurações Principais

```lua
ESPModule.Settings = {
    Enabled = false,                 -- Ativar ESP
    TeamCheck = false,               -- Não mostrar teammates
    AliveCheck = true,               -- Só mostrar players vivos
    MaxDistance = 5000,              -- Distância máxima
    UseTeamColor = true,             -- Usar cor de time
    TeamColor = Color3.fromRGB(0, 255, 0),      -- Cor aliado
    EnemyColor = Color3.fromRGB(255, 0, 0),     -- Cor inimigo
}
```

#### Boxes

```lua
ESPModule.Boxes = {
    Enabled = true,                  -- Ativar boxes
    Type = "2D",                     -- 2D ou 3D
    Color = Color3.fromRGB(255, 255, 255),      -- Cor
    Thickness = 2,                   -- Espessura
    Transparency = 1,                -- Transparência
    Filled = false,                  -- Preenchido
    FilledTransparency = 0.1,        -- Transparência do preenchimento
}
```

#### Tracers

```lua
ESPModule.Tracers = {
    Enabled = true,                  -- Ativar tracers
    From = "Bottom",                 -- Bottom, Center, Mouse
    Color = Color3.fromRGB(255, 255, 255),      -- Cor
    Thickness = 1,                   -- Espessura
    Transparency = 1,                -- Transparência
}
```

#### Names

```lua
ESPModule.Names = {
    Enabled = true,                  -- Ativar nomes
    Color = Color3.fromRGB(255, 255, 255),      -- Cor
    Size = 16,                       -- Tamanho
    Font = Drawing.Fonts.UI,         -- Fonte
    Outline = true,                  -- Contorno
    OutlineColor = Color3.fromRGB(0, 0, 0),     -- Cor do contorno
    ShowDistance = true,             -- Mostrar distância
    ShowHealth = true,               -- Mostrar vida
}
```

#### Health Bar

```lua
ESPModule.HealthBar = {
    Enabled = true,                  -- Ativar barra de vida
    Position = "Left",               -- Left, Right, Top, Bottom
    Size = 4,                        -- Tamanho
    Offset = 4,                      -- Distância do box
    Background = true,               -- Mostrar fundo
    BackgroundColor = Color3.fromRGB(0, 0, 0),  -- Cor do fundo
    HealthyColor = Color3.fromRGB(0, 255, 0),   -- Vida alta
    DamagedColor = Color3.fromRGB(255, 255, 0), -- Vida média
    CriticalColor = Color3.fromRGB(255, 0, 0),  -- Vida baixa
}
```

#### Head Dots

```lua
ESPModule.HeadDots = {
    Enabled = false,                 -- Ativar head dots
    Color = Color3.fromRGB(255, 255, 255),      -- Cor
    Size = 8,                        -- Tamanho
    Filled = true,                   -- Preenchido
    Transparency = 1,                -- Transparência
}
```

#### Chams

```lua
ESPModule.Chams = {
    Enabled = false,                 -- Ativar chams
    Color = Color3.fromRGB(255, 100, 255),      -- Cor
    Transparency = 0.3,              -- Transparência
    VisibleOnly = false,             -- Só quando visível
}
```

#### Métodos

```lua
ESPModule:Init()                 -- Inicializar módulo
ESPModule:Disable()              -- Desativar módulo
```

#### Exemplo Completo

```lua
-- Carregar módulo
local ESP = loadstring(game:HttpGet("URL"))()
ESP:Init()

-- Configurar ESP básico
ESP.Settings.Enabled = true
ESP.Settings.TeamCheck = true

-- Configurar Boxes
ESP.Boxes.Enabled = true
ESP.Boxes.Type = "2D"
ESP.Boxes.Filled = true

-- Configurar Tracers
ESP.Tracers.Enabled = true
ESP.Tracers.From = "Bottom"

-- Configurar Names
ESP.Names.Enabled = true
ESP.Names.ShowDistance = true
ESP.Names.ShowHealth = true

-- Configurar Health Bar
ESP.HealthBar.Enabled = true
ESP.HealthBar.Position = "Left"

-- Configurar Chams
ESP.Chams.Enabled = true
ESP.Chams.Color = Color3.fromRGB(255, 0, 255)
ESP.Chams.Transparency = 0.5
```

---

### 🎨 VISUAL CUSTOMIZATION

#### Exemplo: ESP com Cor de Time

```lua
ESP.Settings.UseTeamColor = true
ESP.Settings.TeamColor = Color3.fromRGB(0, 255, 0)   -- Verde para aliados
ESP.Settings.EnemyColor = Color3.fromRGB(255, 0, 0)  -- Vermelho para inimigos
```

#### Exemplo: Health Bar Dinâmica

```lua
ESP.HealthBar.Enabled = true
ESP.HealthBar.HealthyColor = Color3.fromRGB(0, 255, 0)    -- >60% vida
ESP.HealthBar.DamagedColor = Color3.fromRGB(255, 255, 0)  -- 30-60% vida
ESP.HealthBar.CriticalColor = Color3.fromRGB(255, 0, 0)   -- <30% vida
```

---

## 🔧 VISIBILITY CHECK

### Como Funciona

O sistema de Visibility Check verifica se há paredes/objetos entre você e o target usando raycasting.

### Uso

```lua
-- No Aimbot
AimbotModule.Settings.VisibleCheck = true  -- Só mirar em visíveis

-- No ESP
-- ESP automaticamente usa visibility check em conjunto com wall check
```

---

## 🎣 HOOK SYSTEM

### Hooks Disponíveis

| Hook | Quando Dispara | Parâmetros |
|------|---------------|------------|
| `AimbotInitialized` | Aimbot inicializado | - |
| `AimbotActivated` | Aimbot ativado | - |
| `AimbotDeactivated` | Aimbot desativado | - |
| `AimbotDisabled` | Aimbot desligado completamente | - |
| `ESPInitialized` | ESP inicializado | - |
| `ESPDisabled` | ESP desligado completamente | - |
| `HubLoaded` | Hub carregado | - |

### Exemplo de Uso

```lua
-- Registrar hook
getgenv().firehook("AimbotActivated", function()
    print("Aimbot ativado!")
    -- Seu código aqui
end)

-- Múltiplos hooks
getgenv().firehook("ESPInitialized", function()
    print("ESP pronto!")
end)

getgenv().firehook("HubLoaded", function()
    print("Hub totalmente carregado!")
end)
```

---

## 💡 Exemplos de Configurações Prontas

### Config 1: Aimbot Legit

```lua
-- Aimbot suave e discreto
Aimbot.Settings.Enabled = true
Aimbot.Settings.TeamCheck = true
Aimbot.Settings.VisibleCheck = true
Aimbot.Settings.TargetPart = "Head"
Aimbot.Settings.Smoothing = 0.25        -- Bem suave
Aimbot.Settings.PredictionEnabled = false
Aimbot.FOV.Radius = 100                 -- FOV pequeno
Aimbot.FOV.Visible = false              -- Sem círculo visível
```

### Config 2: Aimbot Rage

```lua
-- Aimbot agressivo
Aimbot.Settings.Enabled = true
Aimbot.Settings.TeamCheck = false
Aimbot.Settings.VisibleCheck = false
Aimbot.Settings.TargetPart = "Head"
Aimbot.Settings.Smoothing = 0           -- Instant lock
Aimbot.Settings.PredictionEnabled = true
Aimbot.Settings.PredictionAmount = 0.15
Aimbot.FOV.Radius = 500                 -- FOV grande
Aimbot.Settings.StickyLock = true       -- Manter lock
```

### Config 3: ESP Minimalista

```lua
-- ESP clean e discreto
ESP.Settings.Enabled = true
ESP.Settings.TeamCheck = true

ESP.Boxes.Enabled = true
ESP.Boxes.Type = "2D"
ESP.Boxes.Filled = false

ESP.Tracers.Enabled = false             -- Sem tracers

ESP.Names.Enabled = true
ESP.Names.ShowDistance = true
ESP.Names.ShowHealth = false

ESP.HealthBar.Enabled = true
ESP.HealthBar.Position = "Left"

ESP.HeadDots.Enabled = false
ESP.Chams.Enabled = false
```

### Config 4: ESP Completo

```lua
-- ESP com tudo ativado
ESP.Settings.Enabled = true
ESP.Settings.UseTeamColor = true

ESP.Boxes.Enabled = true
ESP.Boxes.Type = "3D"
ESP.Boxes.Filled = true

ESP.Tracers.Enabled = true
ESP.Tracers.From = "Bottom"

ESP.Names.Enabled = true
ESP.Names.ShowDistance = true
ESP.Names.ShowHealth = true

ESP.HealthBar.Enabled = true
ESP.HealthBar.Position = "Left"

ESP.HeadDots.Enabled = true
ESP.HeadDots.Filled = true

ESP.Chams.Enabled = true
ESP.Chams.Color = Color3.fromRGB(255, 100, 255)
```

---

## 🛠️ Troubleshooting

### Aimbot não funciona

**Possíveis causas:**
- `VisibleCheck` ativado com walls no meio
- `FOV` muito pequeno
- `TeamCheck` ativado mas todos são teammates
- Parte do corpo inexistente no jogo

**Soluções:**
```lua
Aimbot.Settings.VisibleCheck = false
Aimbot.FOV.Radius = 500
Aimbot.Settings.TeamCheck = false
Aimbot.Settings.TargetPart = "HumanoidRootPart"  -- Tentar outra parte
```

### ESP não aparece

**Possíveis causas:**
- Drawing library não suportada
- Distância muito longe
- Players estão no seu time

**Soluções:**
```lua
ESP.Settings.MaxDistance = 10000
ESP.Settings.TeamCheck = false
```

### Performance ruim

**Soluções:**
```lua
-- Desativar recursos pesados
ESP.Chams.Enabled = false          -- Chams são pesados
ESP.Boxes.Type = "2D"              -- 2D é mais leve que 3D
Aimbot.FOV.Sides = 32              -- Menos lados no círculo
```

---

## 📊 Compatibilidade

### Executores Testados

- ✅ **Synapse X** - Totalmente compatível
- ✅ **Script-Ware** - Totalmente compatível
- ✅ **KRNL** - Compatível (Drawing pode ter limitações)
- ✅ **Fluxus** - Compatível
- ✅ **Electron** - Compatível
- ⚠️ **Outros** - Podem ter limitações com Drawing

### Jogos Testados

- ✅ **FPS Games** - Arsenal, Phantom Forces, Counter Blox
- ✅ **Shooter Games** - Bad Business, Typical Colors 2
- ✅ **Battle Royale** - Island Royale
- ✅ **Combat Games** - Criminality, The Streets

---

## 🤝 Suporte

- **Discord:** discord.gg/darpahub
- **GitHub:** github.com/darpahub
- **Issues:** Reporte bugs na página de issues

---

## 📄 Licença

MIT License - Livre para uso pessoal e comercial

---

## 🎉 Changelog

### v7.5 (Atual) - Ultimate Edition
- ✨ Aimbot completo com FOV, Prediction, Smoothing
- 👁️ ESP premium com Boxes, Tracers, Names, Health Bars
- 🎯 Chams (highlight de corpo inteiro)
- 📍 Head Dots
- 🔍 Visibility Check avançado
- 🎨 Sistema de cores dinâmico (team colors, health colors)
- ⚡ Performance otimizada
- 🎣 Hook System completo
- 💾 Configs prontas
- 📱 Suporte para múltiplos jogos
- 🚀 UI melhorada e mais responsiva

---

**Desenvolvido com 💙 por DarpaHub Team**

*Inspirado no AirHub by Exunys, mas completamente reescrito e melhorado*
