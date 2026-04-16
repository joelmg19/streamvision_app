import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewPlayerScreen extends StatefulWidget {
  final String tmdbId;
  final String title;

  // ── NUEVAS VARIABLES PARA SOPORTAR SERIES ──
  final String type; // Puede ser 'movie' o 'tv'
  final int? season;
  final int? episode;

  const WebviewPlayerScreen({
    super.key,
    required this.tmdbId,
    required this.title,
    required this.type, // Requerido para saber si es peli o serie
    this.season,
    this.episode,
  });

  @override
  State<WebviewPlayerScreen> createState() => _WebviewPlayerScreenState();
}

class _WebviewPlayerScreenState extends State<WebviewPlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  // ── ESCUDO DE NAVEGACIÓN (LISTA NEGRA) ──
  final List<String> _adKeywords = [
    'adsterra', 'popunder', 'bet', 'casino', 'ads', 'tracking',
    'affiliate', 'propellerads', 'popcash', 'monetag', 'exoclick',
    'doubleclick', 'googleadservices', 'scorecardresearch', 'taboola',
    'outbrain', 'porno', 'xxx', 'adult', 'sex', 'redirect', 'click',
    'promo', 'banner', 'sponsor', 'track', 'analytics', 'adsystem',
    'adserver', 'pop', 'popup', 'rtb'
  ];

  @override
  void initState() {
    super.initState();

    // Forzar pantalla horizontal y modo inmersivo
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // ── LÓGICA DE URL: PELÍCULA VS SERIE ──
    String url = '';
    if (widget.type == 'tv' && widget.season != null && widget.episode != null) {
      // URL para un capítulo de una serie
      url = 'https://vidsrc.to/embed/tv/${widget.tmdbId}/${widget.season}/${widget.episode}';
    } else {
      // URL para una película
      url = 'https://vidsrc.to/embed/movie/${widget.tmdbId}';
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);

            _controller.runJavaScript('''
              // Bloquear ventanas emergentes nativas
              window.open = function() { return null; };
              document.querySelectorAll('a').forEach(link => {
                link.removeAttribute('target');
              });
              
              // 1. MENTIRLE A LOS CASINOS: Hacemos creer al sistema base que ya estamos en fullscreen
              Object.defineProperty(document, 'fullscreenElement', { get: () => document.body });
              Object.defineProperty(document, 'webkitFullscreenElement', { get: () => document.body });
              Object.defineProperty(document, 'mozFullScreenElement', { get: () => document.body });

              // 2. FAKE FULLSCREEN CSS: Red de seguridad visual por si el usuario toca la barra de Android
              var style = document.createElement('style');
              style.innerHTML = `
                html, body { margin: 0 !important; padding: 0 !important; width: 100vw !important; height: 100vh !important; overflow: hidden !important; background-color: black !important; }
                iframe { position: fixed !important; top: 0 !important; left: 0 !important; width: 100vw !important; height: 100vh !important; border: none !important; z-index: 99999 !important; }
                .jw-plugin-googima, .jw-ads, .vjs-ad-overlay, .video-ads, .ad-container, .ima-ad-container, [id*="ad-"], [class*="ad-"], [id*="popup"], [class*="popup"] { display: none !important; opacity: 0 !important; pointer-events: none !important; z-index: -1 !important; }
              `;
              document.head.appendChild(style);

              // 3. CAPA MÁGICA: Absorbe el primer clic y lanza la Pantalla Completa Nativa
              var overlay = document.createElement('div');
              overlay.id = 'anti-ad-overlay';
              overlay.style.position = 'fixed';
              overlay.style.top = '0';
              overlay.style.left = '0';
              overlay.style.width = '100vw';
              overlay.style.height = '100vh';
              overlay.style.zIndex = '2147483647';
              overlay.style.backgroundColor = 'rgba(0,0,0,0.85)';
              overlay.style.display = 'flex';
              overlay.style.flexDirection = 'column';
              overlay.style.justifyContent = 'center';
              overlay.style.alignItems = 'center';
              overlay.style.color = 'white';
              overlay.style.fontFamily = 'sans-serif';
              overlay.innerHTML = `
                <div style="font-size: 50px; margin-bottom: 10px;">🍿</div>
                <div style="font-size: 20px; font-weight: bold; text-align: center;">TOCA LA PANTALLA AQUÍ</div>
                <div style="font-size: 14px; margin-top: 8px; color: #ffeb3b; text-align: center;">Para bloquear anuncios y activar pantalla completa</div>
              `;
              document.body.appendChild(overlay);

              overlay.addEventListener('click', function(e) {
                e.preventDefault();
                
                // --- INICIO DE PANTALLA COMPLETA NATIVA ---
                var iframe = document.querySelector('iframe');
                if (iframe) {
                    // Le damos permisos al iframe por si el servidor olvidó ponérselos
                    iframe.setAttribute('allowfullscreen', 'true');
                    iframe.setAttribute('webkitallowfullscreen', 'true');
                    iframe.setAttribute('mozallowfullscreen', 'true');
                    
                    // Forzamos el comando oficial para desactivar los scripts del casino
                    if (iframe.requestFullscreen) { iframe.requestFullscreen(); }
                    else if (iframe.webkitRequestFullscreen) { iframe.webkitRequestFullscreen(); }
                }
                // --- FIN DE PANTALLA COMPLETA NATIVA ---
                
                // Destruimos la capa mágica
                overlay.remove(); 
              });

              // 4. BUCLE DESTRUCTOR: Escanea buscando popups invisibles
              setInterval(function() {
                var elements = document.querySelectorAll('div, iframe');
                elements.forEach(function(el) {
                  var compStyle = window.getComputedStyle(el);
                  var zIndex = parseInt(compStyle.zIndex);
                  
                  if (!isNaN(zIndex) && zIndex > 900 && el.tagName !== 'IFRAME') {
                    var className = (el.className || '').toString().toLowerCase();
                    var idName = (el.id || '').toString().toLowerCase();
                    
                    if (className.includes('ad') || idName.includes('ad') || 
                        className.includes('overlay') || className.includes('sponsor')) {
                      el.style.display = 'none';
                      el.style.pointerEvents = 'none';
                    }
                  }
                });
              }, 500);
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            final urlString = request.url.toLowerCase();

            // Solo permitir dominios seguros
            if (urlString.contains('vidsrc.to') || urlString.contains('vsembed.ru')) {
              return NavigationDecision.navigate;
            }

            // Bloquear si coincide con nuestra lista negra
            for (final keyword in _adKeywords) {
              if (urlString.contains(keyword)) {
                return NavigationDecision.prevent;
              }
            }

            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  void dispose() {
    // Restaurar verticalidad al salir de la pantalla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ignoramos todas las SafeAreas para que ocupe toda la pantalla
          SafeArea(
            bottom: false, top: false, left: false, right: false,
            child: WebViewWidget(controller: _controller),
          ),

          // Rueda de carga inicial
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Botón X para cerrar la película manualmente
          Positioned(
            top: 24,
            left: 24,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24)
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}