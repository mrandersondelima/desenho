# Camera Overlay App

Uma aplicação Flutter que permite sobrepor imagens com transparência ajustável sobre a visualização da câmera usando GetX para gerenciamento de estado.

## Funcionalidades

- 📸 **Visualização da câmera em tempo real**
- 🖼️ **Seleção de imagens da galeria**
- 🔍 **Transparência ajustável** (0-100%)
- 📱 **Troca entre câmeras** (frontal/traseira)
- ✋ **Controles gestuais**:
  - Arrastar para mover a imagem
  - Pinça para redimensionar
- 👁️ **Alternar visibilidade** da sobreposição
- 🔄 **Reset das transformações**

## Tecnologias Utilizadas

- **Flutter**: Framework de desenvolvimento
- **GetX**: Gerenciamento de estado reativo
- **Camera**: Plugin para acesso à câmera
- **File Picker**: Seleção de arquivos
- **Permission Handler**: Gerenciamento de permissões

## Como Usar

1. **Iniciar o app**: A câmera será inicializada automaticamente
2. **Selecionar imagem**: Toque no botão azul (📷) para escolher uma imagem
3. **Ajustar transparência**: Use o slider na parte inferior
4. **Mover a imagem**: Arraste a imagem na tela
5. **Redimensionar**: Use o gesto de pinça (zoom)
6. **Trocar câmera**: Toque no botão verde para alternar entre front/back
7. **Ocultar/mostrar**: Toque no botão laranja para alternar visibilidade
8. **Reset**: Toque no botão vermelho para resetar posição e escala

## Permissões Necessárias

- **Câmera**: Para visualização em tempo real
- **Armazenamento**: Para acessar imagens da galeria

## Estrutura do Projeto

```
lib/
├── main.dart                     # Ponto de entrada da aplicação
├── controller/
│   └── camera_controller.dart    # Controller GetX para gerenciar estado
└── screens/
    └── camera_overlay_screen.dart # Tela principal da aplicação
```

## Executando o Projeto

1. Certifique-se de ter o Flutter instalado
2. Clone o repositório
3. Execute os comandos:

```bash
flutter pub get
flutter run
```

## Observações

- Testado em Android
- Requer dispositivo físico (câmera não funciona no emulador)
- Funciona melhor com imagens PNG com transparência
