import 'package:chat_jyotishi/features/home/bloc/home_client_bloc.dart';
import 'package:chat_jyotishi/features/home/bloc/home_client_events.dart';
import 'package:chat_jyotishi/features/home/bloc/home_client_states.dart';
import 'package:chat_jyotishi/features/home/models/rotating_question.dart';
import 'package:chat_jyotishi/features/home/repository/home_client_repository.dart';
import 'package:chat_jyotishi/features/home/service/home_client_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_jyotishi/constants/constant.dart';

class RotatingQuestionsWidget extends StatefulWidget {
  const RotatingQuestionsWidget({super.key});

  @override
  State<RotatingQuestionsWidget> createState() =>
      _RotatingQuestionsWidgetState();
}

class _RotatingQuestionsWidgetState extends State<RotatingQuestionsWidget>
    with SingleTickerProviderStateMixin {
  Timer? _rotationTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late HomeClientBloc _bloc;

  List<String> _currentTitleWords = [];
  List<String> _currentSubtitleWords = [];
  int _visibleTitleWords = 0;
  int _visibleSubtitleWords = 0;
  Timer? _wordTimer;

  @override
  void initState() {
    super.initState();

    // Initialize BLoC internally
    _bloc = HomeClientBloc(
      repository: HomeClientRepository(HomeClientService()),
    );

    // Load questions immediately
    _bloc.add(LoadRotatingQuestionsEvent());

    // Animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _wordTimer?.cancel();
    _rotationTimer?.cancel();
    _fadeController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _startRotationTimer(BuildContext context) {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Only update the question, container remains visible
      _bloc.add(NextQuestionEvent());
    });
  }

  void _startWordAnimation(RotatingQuestion question) {
    _currentTitleWords = question.title.split(' ');
    _currentSubtitleWords = question.subtitle.split(' ');
    _visibleTitleWords = 0;
    _visibleSubtitleWords = 0;

    _fadeController.forward();

    _wordTimer?.cancel();
    _wordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_visibleTitleWords < _currentTitleWords.length) {
          _visibleTitleWords++;
        } else if (_visibleSubtitleWords < _currentSubtitleWords.length) {
          _visibleSubtitleWords++;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeClientBloc>.value(
      value: _bloc,
      child: BlocConsumer<HomeClientBloc, HomeClientState>(
        listener: (context, state) {
          if (state is RotatingQuestionsLoadedState) {
            _startWordAnimation(state.currentQuestion);
            _startRotationTimer(context);
          }
        },
        builder: (context, state) {
          // Always return a fixed-size container
          return _buildFixedContainer(state);
        },
      ),
    );
  }

  Widget _buildFixedContainer(HomeClientState state) {
    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.5),
            AppColors.cosmicPink.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _buildContent(state),
    );
  }

  Widget _buildContent(HomeClientState state) {
    if (state is HomeClientLoadingState) {
      return _buildLoadingContent();
    }

    if (state is HomeClientErrorState) {
      return _buildErrorContent(state.message);
    }

    if (state is RotatingQuestionsEmptyState) {
      return _buildEmptyContent();
    }

    if (state is RotatingQuestionsLoadedState) {
      return _buildQuestionContent(state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildQuestionContent(RotatingQuestionsLoadedState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reserve a fixed height for the question content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(
                    _visibleTitleWords,
                    (index) => _AnimatedWord(
                      word: _currentTitleWords[index],
                      index: index,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(
                    _visibleSubtitleWords,
                    (index) => _AnimatedWord(
                      word: _currentSubtitleWords[index],
                      index: index,
                      style: const TextStyle(
                        color: gold,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.chat_bubble_outline,
                title: 'Instant Guidance',
                description:
                    'Verified Jyotish सँग real-time chat गरेर तुरुन्त उत्तर पाउनुहोस्।',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.auto_awesome,
                title: 'Personalized Insights',
                description:
                    'जन्म विवरण अनुसार kundali review, match, र future predictions।',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.15),
            AppColors.deepPurple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 16),
          ),
          const SizedBox(width: 8), // horizontal spacing in Row
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  description,
                  style: const TextStyle(
                    color: gold,
                    fontSize: 10,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryPurple,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorContent(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 32),
          const SizedBox(height: 8),
          Text(
            'Failed to load questions',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.question_mark_outlined,
            color: AppColors.textMuted,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'No questions available',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _AnimatedWord extends StatefulWidget {
  final String word;
  final int index;
  final TextStyle style;

  const _AnimatedWord({
    required this.word,
    required this.index,
    required this.style,
  });

  @override
  State<_AnimatedWord> createState() => _AnimatedWordState();
}

class _AnimatedWordState extends State<_AnimatedWord>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Text(widget.word, style: widget.style),
      ),
    );
  }
}
