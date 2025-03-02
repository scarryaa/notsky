import 'package:flutter/material.dart';

enum SlideDirection { up, down, none }

class ImageDetailScreen extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;
  final VoidCallback onExit;

  const ImageDetailScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.onExit,
  });

  @override
  ImageDetailScreenState createState() => ImageDetailScreenState();
}

class ImageDetailScreenState extends State<ImageDetailScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late PageController _pageController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isZoomed = false;
  bool _isSliding = false;
  bool _isUIVisible = true;

  bool _isFirstPointerDown = false;
  int _activePointers = 0;

  void _toggleUIVisibility() {
    setState(() {
      _isUIVisible = !_isUIVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController.addListener(_onTransformationChanged);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onExit();
        Navigator.of(context).pop();
      }
    });
  }

  void _onTransformationChanged() {
    bool newIsZoomed =
        _transformationController.value.getMaxScaleOnAxis() > 1.05;
    if (newIsZoomed != _isZoomed) {
      setState(() {
        _isZoomed = newIsZoomed;
      });
    }
  }

  void _startSlideAnimation(SlideDirection direction) {
    if (_isZoomed || _isSliding) return;

    setState(() {
      _isSliding = true;

      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end:
            direction == SlideDirection.up
                ? const Offset(0, -1)
                : const Offset(0, 1),
      ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
      );
    });

    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) async {
        widget.onExit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                return Transform.translate(
                  offset:
                      _slideAnimation.value *
                      MediaQuery.of(context).size.height,
                  child: child,
                );
              },
              child: Listener(
                onPointerDown: (PointerDownEvent event) {
                  setState(() {
                    _activePointers++;
                    if (_activePointers == 1) {
                      _isFirstPointerDown = true;
                    } else if (_activePointers == 2 && _isFirstPointerDown) {
                      _isZoomed = true;
                    }
                  });
                },
                onPointerUp: (PointerUpEvent event) {
                  setState(() {
                    _activePointers =
                        _activePointers > 0 ? _activePointers - 1 : 0;
                    if (_activePointers == 0) {
                      _isFirstPointerDown = false;
                    }
                  });
                },
                onPointerCancel: (PointerCancelEvent event) {
                  setState(() {
                    _activePointers =
                        _activePointers > 0 ? _activePointers - 1 : 0;
                    if (_activePointers == 0) {
                      _isFirstPointerDown = false;
                    }
                  });
                },
                child: GestureDetector(
                  onTap: _toggleUIVisibility,
                  onVerticalDragEnd:
                      _isZoomed
                          ? null
                          : (details) {
                            final velocity =
                                details.velocity.pixelsPerSecond.dy;
                            if (velocity.abs() > 300) {
                              if (velocity < 0) {
                                _startSlideAnimation(SlideDirection.up);
                              } else {
                                _startSlideAnimation(SlideDirection.down);
                              }
                            }
                          },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    physics:
                        _isZoomed || _isSliding
                            ? const NeverScrollableScrollPhysics()
                            : const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 3.0,
                        panEnabled: true,
                        scaleEnabled: true,
                        onInteractionStart: (details) {
                          if (details.pointerCount >= 2) {
                            setState(() {
                              _isZoomed = true;
                            });
                          }
                        },
                        onInteractionEnd: (details) {
                          if (_transformationController.value
                                  .getMaxScaleOnAxis() <
                              1.05) {
                            _transformationController.value =
                                Matrix4.identity();
                          }
                          setState(() {
                            _isZoomed =
                                _transformationController.value
                                    .getMaxScaleOnAxis() >
                                1.05;
                          });
                        },
                        child: Center(
                          child: GestureDetector(
                            onDoubleTapDown: (TapDownDetails details) {
                              if (_isZoomed) {
                                _transformationController.value =
                                    Matrix4.identity();
                                setState(() {
                                  _isZoomed = false;
                                });
                              } else {
                                final RenderBox renderBox =
                                    context
                                            .findAncestorRenderObjectOfType<
                                              RenderBox
                                            >()
                                        as RenderBox;
                                final Offset localPosition = renderBox
                                    .globalToLocal(details.globalPosition);

                                final Size size = renderBox.size;

                                final double focalPointX =
                                    localPosition.dx / size.width;
                                final double focalPointY =
                                    localPosition.dy / size.height;

                                final Matrix4 newMatrix =
                                    Matrix4.identity()
                                      ..translate(
                                        size.width * (1 - 3.0) * focalPointX,
                                        size.height * (1 - 3.0) * focalPointY,
                                      )
                                      ..scale(3.0);

                                _transformationController.value = newMatrix;
                                setState(() {
                                  _isZoomed = true;
                                });
                              }
                            },
                            child: Image.network(
                              widget.images[index].fullsize,
                              fit: BoxFit.contain,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _isUIVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                color: Colors.black.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        widget.onExit();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
