import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/shared/widgets/index.dart';
import 'package:aethera/features/memory_vaults/models/memory_vault.dart';
import 'package:aethera/features/memory_vaults/providers/vault_provider.dart';
import 'package:aethera/features/memory_vaults/widgets/vault_card.dart';
import 'package:aethera/features/auth/providers/auth_provider.dart';

class VaultsScreen extends ConsumerStatefulWidget {
  const VaultsScreen({super.key});

  @override
  ConsumerState<VaultsScreen> createState() => _VaultsScreenState();
}

class _VaultsScreenState extends ConsumerState<VaultsScreen> {
  String selectedRevealCondition = 'immediate';
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void _showCreateVaultSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AetheraTokens.cosmicNight,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AetheraTokens.spacingLg),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Memory Vault',
                      style: AetheraTokens.displaySmall(),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    AetheraGlassPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Memory title...',
                          hintStyle: AetheraTokens.bodyMedium(
                            color: AetheraTokens.dusk,
                          ),
                          border: InputBorder.none,
                        ),
                        style: AetheraTokens.bodyMedium(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Content
                    AetheraGlassPanel(
                      padding: const EdgeInsets.all(AetheraTokens.spacingMd),
                      child: TextField(
                        controller: contentController,
                        decoration: InputDecoration(
                          hintText: 'Write your secret memory...',
                          hintStyle: AetheraTokens.bodyMedium(
                            color: AetheraTokens.dusk,
                          ),
                          border: InputBorder.none,
                        ),
                        style: AetheraTokens.bodyMedium(),
                        maxLines: 5,
                        minLines: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Reveal condition
                    Text(
                      'Reveal Condition',
                      style: AetheraTokens.labelLarge(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'immediate',
                        'challenge_complete',
                        'anniversary',
                        'birthday',
                      ].map((condition) {
                        final isSelected =
                            selectedRevealCondition == condition;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() =>
                                  selectedRevealCondition = condition),
                          child: NeonBorderCard(
                            neonColor: isSelected
                                ? AetheraTokens.auroraTeal
                                : AetheraTokens.moonGlow,
                            borderRadius: AetheraTokens.radiusSm,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              condition,
                              style: AetheraTokens.labelSmall(
                                color: isSelected
                                    ? AetheraTokens.auroraTeal
                                    : AetheraTokens.moonGlow,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Create button
                    SizedBox(
                      width: double.infinity,
                      child: LiquidButton(
                        label: 'Create Vault',
                        onPressed: () {
                          final userId = ref.read(authProvider)?.uid;
                          if (userId != null) {
                            final vault = MemoryVault(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              authorId: userId,
                              title: titleController.text,
                              content: contentController.text,
                              createdAt: DateTime.now(),
                              revealCondition: selectedRevealCondition,
                            );

                            ref.read(createVaultProvider(vault));
                            Navigator.pop(context);
                            titleController.clear();
                            contentController.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaults = ref.watch(allMemoryVaultsProvider);
    final revealable = ref.watch(revealableVaultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Vaults'),
        centerTitle: true,
        backgroundColor: AetheraTokens.deepSpace,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateVaultSheet,
        backgroundColor: AetheraTokens.auroraTeal,
        child: Icon(
          Icons.add,
          color: AetheraTokens.deepSpace,
        ),
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
        child: vaults.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Text('Error: $err', style: AetheraTokens.bodyMedium()),
          ),
          data: (vaultList) {
            if (vaultList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 64,
                      color: AetheraTokens.moonGlow,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No vaults yet',
                      style: AetheraTokens.displaySmall(
                        color: AetheraTokens.moonGlow,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first secret memory',
                      style: AetheraTokens.bodyMedium(
                        color: AetheraTokens.dusk,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AetheraTokens.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Memory Vaults',
                    style: AetheraTokens.displayMedium(),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: vaultList.length,
                    itemBuilder: (context, index) {
                      final vault = vaultList[index];
                      return VaultCard(
                        vault: vault,
                        onReveal: () =>
                            ref.read(revealVaultProvider(vault.id)),
                        onDelete: () =>
                            ref.read(deleteVaultProvider(vault.id)),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
