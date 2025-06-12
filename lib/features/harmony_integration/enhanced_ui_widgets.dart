import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced UI widgets integrated from Harmony-Music
/// Provides improved visual components and animations

/// Enhanced song list tile with better animations and interactions
class EnhancedSongListTile extends StatefulWidget {
  final String title;
  final String artist;
  final String? album;
  final String? imageUrl;
  final Duration? duration;
  final bool isPlaying;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onMore;
  final VoidCallback? onDownload;

  const EnhancedSongListTile({
    super.key,
    required this.title,
    required this.artist,
    this.album,
    this.imageUrl,
    this.duration,
    this.isPlaying = false,
    this.isLiked = false,
    this.onTap,
    this.onLike,
    this.onMore,
    this.onDownload,
  });

  @override
  State<EnhancedSongListTile> createState() => EnhancedSongListTileStateState();
}

class EnhancedSongListTileStateState extends State<EnhancedSongListTile>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _playingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _playingAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _playingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _playingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _playingController,
      curve: Curves.easeInOut,
    ));

    if (widget.isPlaying) {
      _playingController.forward();
    }
  }

  @override
  void didUpdateWidget(EnhancedSongListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _playingController.forward();
      } else {
        _playingController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _playingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.isPlaying 
                  ? theme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap?.call();
                },
                onTapDown: (_) => _scaleController.forward(),
                onTapUp: (_) => _scaleController.reverse(),
                onTapCancel: () => _scaleController.reverse(),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Album art with playing indicator
                      _buildAlbumArt(theme),
                      const SizedBox(width: 12),
                      
                      // Song info
                      Expanded(
                        child: _buildSongInfo(theme),
                      ),
                      
                      // Duration
                      if (widget.duration != null)
                        _buildDuration(theme),
                      
                      const SizedBox(width: 8),
                      
                      // Action buttons
                      _buildActionButtons(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(ThemeData theme) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: widget.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAlbumArt(theme),
                  ),
                )
              : _buildDefaultAlbumArt(theme),
        ),
        
        // Playing indicator
        AnimatedBuilder(
          animation: _playingAnimation,
          builder: (context, child) {
            return Positioned.fill(
              child: Opacity(
                opacity: _playingAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.primaryColor.withOpacity(0.8),
                  ),
                  child: const Icon(
                    Icons.equalizer,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDefaultAlbumArt(ThemeData theme) {
    return Icon(
      Icons.music_note,
      color: theme.colorScheme.onSurfaceVariant,
      size: 24,
    );
  }

  Widget _buildSongInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: widget.isPlaying ? FontWeight.w600 : FontWeight.w500,
            color: widget.isPlaying 
                ? theme.primaryColor 
                : theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          widget.album != null 
              ? '${widget.artist} • ${widget.album}'
              : widget.artist,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDuration(ThemeData theme) {
    final duration = widget.duration!;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    return Text(
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        IconButton(
          icon: Icon(
            widget.isLiked ? Icons.favorite : Icons.favorite_border,
            color: widget.isLiked ? Colors.red : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onLike?.call();
          },
          visualDensity: VisualDensity.compact,
        ),
        
        // Download button
        if (widget.onDownload != null)
          IconButton(
            icon: Icon(
              Icons.download_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onDownload?.call();
            },
            visualDensity: VisualDensity.compact,
          ),
        
        // More options
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onMore?.call();
          },
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// Enhanced loading shimmer widget
class EnhancedShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const EnhancedShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<EnhancedShimmer> createState() => EnhancedShimmerStateState();
}

class EnhancedShimmerStateState extends State<EnhancedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? theme.colorScheme.surfaceContainerHighest;
    final highlightColor = widget.highlightColor ?? theme.colorScheme.surface.withOpacity(0.8);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Enhanced card widget with better shadows and animations
class EnhancedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool enableHoverEffect;

  const EnhancedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.enableHoverEffect = true,
  });

  @override
  State<EnhancedCard> createState() => EnhancedCardStateState();
}

class EnhancedCardStateState extends State<EnhancedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  // ignore: unused_field
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) + 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin,
            child: Material(
              color: widget.color ?? theme.cardColor,
              elevation: _elevationAnimation.value,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              child: InkWell(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                onTap: widget.onTap,
                onHover: widget.enableHoverEffect ? (hovering) {
                  setState(() {
                    _isHovered = hovering;
                  });
                  if (hovering) {
                    _controller.forward();
                  } else {
                    _controller.reverse();
                  }
                } : null,
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced progress bar with better animations
class EnhancedProgressBar extends StatefulWidget {
  final double progress;
  final double? buffered;
  final Color? progressColor;
  final Color? bufferedColor;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final ValueChanged<double>? onChanged;

  const EnhancedProgressBar({
    super.key,
    required this.progress,
    this.buffered,
    this.progressColor,
    this.bufferedColor,
    this.backgroundColor,
    this.height = 4.0,
    this.borderRadius,
    this.onTap,
    this.onChanged,
  });

  @override
  State<EnhancedProgressBar> createState() => EnhancedProgressBarStateState();
}

class EnhancedProgressBarStateState extends State<EnhancedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: widget.height,
      end: widget.height * 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = widget.progressColor ?? theme.primaryColor;
    final bufferedColor = widget.bufferedColor ?? theme.primaryColor.withOpacity(0.3);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (details) {
            if (widget.onChanged != null) {
              _controller.forward();
              setState(() {
                _isDragging = true;
              });
            }
          },
          onTapUp: (details) {
            if (widget.onChanged != null) {
              _controller.reverse();
              setState(() {
                _isDragging = false;
              });
              
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
              widget.onChanged!(progress);
            } else {
              widget.onTap?.call();
            }
          },
          onPanUpdate: (details) {
            if (widget.onChanged != null && _isDragging) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
              widget.onChanged!(progress);
            }
          },
          onPanEnd: (details) {
            if (widget.onChanged != null) {
              _controller.reverse();
              setState(() {
                _isDragging = false;
              });
            }
          },
          child: Container(
            height: _heightAnimation.value,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(_heightAnimation.value / 2),
            ),
            child: Stack(
              children: [
                // Buffered progress
                if (widget.buffered != null)
                  FractionallySizedBox(
                    widthFactor: widget.buffered!.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bufferedColor,
                        borderRadius: widget.borderRadius ?? BorderRadius.circular(_heightAnimation.value / 2),
                      ),
                    ),
                  ),
                
                // Main progress
                FractionallySizedBox(
                  widthFactor: widget.progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: widget.borderRadius ?? BorderRadius.circular(_heightAnimation.value / 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}