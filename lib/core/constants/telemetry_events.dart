abstract final class TelemetryEvents {
  // Inicio
  static const String startupReady = 'startup_ready';
  static const String startupFailed = 'startup_failed';
  static const String startupRetryTapped = 'startup_retry_tapped';
  static const String startupRecovered = 'startup_recovered';
  static const String kpiStartupFailure = 'kpi_startup_failure';

  // Sincronizacion
  static const String syncActionQueued = 'sync_action_queued';
  static const String syncActionSent = 'sync_action_sent';
  static const String syncActionRequeued = 'sync_action_requeued';
  static const String syncActionDropped = 'sync_action_dropped';
  static const String syncQueueFlushed = 'sync_queue_flushed';
  static const String kpiSyncFailure = 'kpi_sync_failure';
  static const String kpiQueueDrop = 'kpi_queue_drop';
}
