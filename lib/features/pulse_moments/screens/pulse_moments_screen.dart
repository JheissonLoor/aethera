import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/shared/widgets/index.dart';
import 'package:aethera/features/pulse_moments/models/pulse_moment.dart';
import 'package:aethera/features/pulse_moments/providers/pulse_moments_provider.dart';
import 'package:aethera/features/pulse_moments/widgets/pulse_animation_widget.dart';

class PulseMomentsScreen extends ConsumerStatefulWidget {
  const PulseMomentsScreen({super.key});

  @override
  ConsumerState<PulseMomentsScreen> createState() => _PulseMomentsScreenState();
}

class _PulseMomentsScreenState extends ConsumerState<PulseMomentsScreen> {
  final List<String> emotionOptions = [
    'love',
    'joy',
    'longing',
    'peace',
    'melancholy',
    'anxious',
  ];

  String selectedEmotion = 'love';
  String? messageText;

  void _sendPulse() async {
    final partnerId = await ref.read(partnerIdProvider.future);
    if (partnerId == null) return;

    final pulse = PulseMoment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: ref.read(authProvider)?.uid ?? '',
      emotion: selectedEmotion,
      message: messageText,
      createdAt: DateTime.now(),
    );

    ref.read(sendPulseProvider(pulse));

    setState(() {
      selectedEmotion = 'love';
      messageText = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pulse sent! Your partner will receive it.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pulses = ref.watch(receivedPulsesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse Moments'),
        centerTitle: true,
        backgroundColor: AetheraTokens.deepSpace,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AetheraTokens.deepSpace,
              AetheraTokens.cosmicNight,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AetheraTokens.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Send Pulse
              Text(
                'Send a Pulse',
                style: AetheraTokens.displayMedium(),
              ),
              const SizedBox(height: 24),

              // Emotion selector
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: emotionOptions.map((emotion) {
                  final isSelected = selectedEmotion == emotion;
                  final color = AetheraTokens.colorForEmotion(emotion);

                  return GestureDetector(
                    onTap: () => setState(() => selectedEmotion = emotion),
                    child: NeonBorderCard(
                      neonColor: isSelected ? color : color.withValues(alpha: 0.4),
                      backgroundColor: isSelected
                          ? color.withValues(alpha: 0.15)
                          : color.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emotion.toUpperCase(),
                            style: AetheraTokens.labelSmall(
                              color: isSelected ? color : AetheraTokens.moonGlow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Optional message
              AetheraGlassPanel(
                padding: const EdgeInsets.all(AetheraTokens.spacingMd),
                child: TextField(
                  onChanged: (value) => setState(() => messageText = value.isEmpty ? null : value),
                  decoration: InputDecoration(
                    hintText: 'Add a message (optional)',
                    hintStyle: AetheraTokens.bodyMedium(color: AetheraTokens.dusk),
                    border: InputBorder.none,
                  ),
                  style: AetheraTokens.bodyMedium(),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(height: 24),

              // Send button
              SizedBox(
                width: double.infinity,
                child: LiquidButton(
                  label: 'Send Pulse',
                  onPressed: _sendPulse,
                  gradientStart: AetheraTokens.roseQuartz,
                  gradientEnd: AetheraTokens.nebulaPurple,
                ),
              ),
              const SizedBox(height: 48),

              // Section: Received Pulses
              Text(
                'Recent Pulses',
                style: AetheraTokens.displayMedium(),
              ),
              const SizedBox(height: 24),

              pulses.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(
                  child: Text('Error: $err', style: AetheraTokens.bodyMedium()),
                ),
                data: (pulseList) {
                  if (pulseList.isEmpty) {
                    return Center(
                      child: Text(
                        'No pulses yet',
                        style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pulseList.length,
                    itemBuilder: (context, index) {
                      final pulse = pulseList[index];
                      final color = AetheraTokens.colorForEmotion(pulse.emotion);

                      return MorphCard(
                        primaryColor: color,
                        secondaryColor: AetheraTokens.nebulaPurple,
                        height: 140,
                        margin: const EdgeInsets.only(bottom: 16),
                        onTap: () => ref.read(acknowledgePulseProvider(pulse.id)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  pulse.emotion.toUpperCase(),
                                  style: AetheraTokens.labelLarge(color: color),
                                ),
                                if (pulse.isAcknowledged)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        AetheraTokens.radiusSm,
                                      ),
                                      color: color.withValues(alpha: 0.2),
                                    ),
                                    child: Text(
                                      'Acknowledged',
                                      style: AetheraTokens.bodySmall(color: color),
                                    ),
                                  ),
                              ],
                            ),
                            if (pulse.message != null)
                              Text(
                                pulse.message!,
                                style: AetheraTokens.bodyMedium(),
                              ),
                            Text(
                              'Tap to acknowledge',
                              style: AetheraTokens.bodySmall(
                                color: AetheraTokens.moonGlow,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
