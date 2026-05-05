/// Pure Dart core for ntech_grid — headless table logic.
/// No Flutter or dart:ui imports allowed in this package.
library grid_core;

// Models
export 'src/models/column_def.dart';
export 'src/models/grid_page.dart';
export 'src/models/grid_query.dart';
export 'src/models/grid_state.dart';
export 'src/models/header_group.dart';
export 'src/models/row_model.dart';

// Commands (all in one file to satisfy sealed class constraint)
export 'src/commands/grid_command.dart';

// Middleware
export 'src/middleware/grid_middleware.dart';

// Pipeline
export 'src/pipeline/pipeline_stage.dart';
export 'src/pipeline/filter_stage.dart';
export 'src/pipeline/sort_stage.dart';
export 'src/pipeline/group_stage.dart';
export 'src/pipeline/expand_stage.dart';
export 'src/pipeline/paginate_stage.dart';
export 'src/pipeline/row_model_pipeline.dart';

// Features
export 'src/features/grid_feature.dart';
export 'src/features/sort_feature.dart';
export 'src/features/filter_feature.dart';
export 'src/features/pagination_feature.dart';
export 'src/features/selection_feature.dart';
export 'src/features/column_visibility_feature.dart';
export 'src/features/column_ordering_feature.dart';
export 'src/features/column_pinning_feature.dart';
export 'src/features/column_sizing_feature.dart';
export 'src/features/row_pinning_feature.dart';
export 'src/features/grouping_feature.dart';
export 'src/features/expanding_feature.dart';
export 'src/features/row_dnd_feature.dart';

// Functions
export 'src/functions/filter_functions.dart';
export 'src/functions/sort_functions.dart';
export 'src/functions/aggregation_functions.dart';

// Data source
export 'src/data_source/grid_data_source.dart';

// Controller
export 'src/controller/grid_options.dart';
export 'src/controller/grid_controller.dart';
