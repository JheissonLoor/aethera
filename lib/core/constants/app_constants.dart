abstract class AppConstants {
  // Timing
  static const Duration splashDuration = Duration(milliseconds: 3500);
  static const Duration animationFast = Duration(milliseconds: 300);
  static const Duration animationMedium = Duration(milliseconds: 600);
  static const Duration animationSlow = Duration(milliseconds: 1000);

  // Universe
  static const int starCount = 150;
  static const int maxConnectionStrength = 100;
  static const int universeMaxLevel = 5;

  // Progression points
  static const int pointsDailyCheckin = 5;
  static const int pointsWeeklyRitual = 15;
  static const int pointsAddMemory = 10;
  static const int pointsSimultaneousOnline = 3;
  static const int pointsGoalComplete = 20;
  static const int pointsSyncRitual = 40;
  static const int syncRitualSeconds = 60;

  // Live sync ritual events
  static const List<String> syncCosmicEvents = [
    'Aurora Gemela',
    'Lluvia de Estrellas',
    'Eclipse de Corazones',
    'Nebulosa de Promesas',
    'Cometa del Reencuentro',
  ];

  // Firestore collections
  static const String colUsers = 'users';
  static const String colCouples = 'couples';
  static const String colMemories = 'memories';
  static const String colGoals = 'goals';
  static const String colCapsules = 'capsules';
  static const String colDailyQuestions = 'daily_questions';
  static const String colRituals = 'rituals';

  // Presence (Realtime DB)
  static const String rtPresence = 'presence';

  // Emotions
  static const List<String> emotions = [
    'joy',
    'love',
    'peace',
    'longing',
    'melancholy',
    'anxious',
  ];

  static const Map<String, String> emotionEmojis = {
    'joy': '✨',
    'love': '💕',
    'peace': '🌊',
    'longing': '🌙',
    'melancholy': '🌧️',
    'anxious': '🌪️',
  };

  static const Map<String, String> emotionLabels = {
    'joy': 'Alegría',
    'love': 'Amor',
    'peace': 'Paz',
    'longing': 'Añoranza',
    'melancholy': 'Melancolía',
    'anxious': 'Ansiedad',
  };

  // Memory types
  static const List<String> memoryTypes = [
    'tree',
    'lighthouse',
    'constellation',
    'bridge',
    'island',
    'relic',
  ];

  static const Map<String, String> memoryTypeIcons = {
    'tree': '🌳',
    'lighthouse': '🏮',
    'constellation': '⭐',
    'bridge': '🌉',
    'island': '🏝️',
    'relic': '🜦',
  };

  static const List<String> preguntasDiarias = [
    '¿Qué pequeño momento de hoy te hizo pensar en mí?',
    '¿Qué te gustaría que vivamos juntos este mes?',
    '¿Qué detalle mío te hace sonreír sin darte cuenta?',
    '¿Qué te gustaría que mejoremos como equipo?',
    '¿Cuál es un recuerdo nuestro que quieres repetir pronto?',
    '¿Qué canción describe cómo te sientes conmigo hoy?',
    '¿Qué te gustaría agradecerme hoy?',
    '¿Qué meta compartida te emociona más ahora?',
    '¿Qué te gustaría que hagamos en nuestra próxima cita?',
    '¿Qué emoción quieres que cuidemos más esta semana?',
    '¿Qué frase te gustaría escuchar de mí hoy?',
    '¿Qué aventura pequeña podríamos empezar juntos?',
    '¿Qué hábito bonito quieres construir entre los dos?',
    '¿Qué parte de nuestra historia te enorgullece más?',
    '¿Qué sueño personal quieres que te acompañe a cumplir?',
    '¿Qué valor sientes más fuerte en nuestra relación?',
    '¿Qué tema te gustaría conversar con calma conmigo?',
    '¿Qué cosa simple te haría sentir más cerca hoy?',
    '¿Qué aprendizaje te dejó nuestra relación este año?',
    '¿Qué promesa te gustaría que nos hagamos hoy?',
  ];
}
