import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../../../recipe/domain/entities/recipe.dart';

/// MCP (Model Context Protocol) 服务
///
/// 封装与 MCP 服务的交互
/// 响应格式: SSE (Server-Sent Events) with JSON-RPC 2.0
class MCPService {
  final Dio _dio;
  late final String baseUrl;
  int _requestId = 0;

  MCPService() : _dio = Dio() {
    baseUrl = dotenv.env['MCP_BASE_URL']!;
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
    };
  }

  /// 调用 MCP 工具（JSON-RPC 2.0 格式）
  ///
  /// [toolName] 工具名称（带 mcp_howtocook_ 前缀）
  /// [arguments] 工具参数
  Future<dynamic> _callTool(String toolName, Map<String, dynamic> arguments) async {
    try {
      _requestId++;

      // JSON-RPC 2.0 请求格式
      final requestData = {
        'jsonrpc': '2.0',
        'id': _requestId,
        'method': 'tools/call',
        'params': {
          'name': 'mcp_howtocook_$toolName', // 添加前缀
          'arguments': arguments,
        },
      };

      final response = await _dio.post(
        '/mcp',
        data: requestData,
      );

      // 解析 SSE 响应
      return _parseSSEResponse(response.data);
    } on DioException catch (e) {
      throw Exception('MCP tool call failed: ${e.message}');
    }
  }

  /// 解析 SSE (Server-Sent Events) 响应
  ///
  /// SSE 格式: event: message\ndata: {...JSON-RPC...}
  dynamic _parseSSEResponse(String data) {
    try {
      // 解析 SSE 格式
      final lines = data.split('\n');
      String? jsonData;

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          jsonData = line.substring(6);
          break;
        }
      }

      if (jsonData == null) {
        throw Exception('No data found in SSE response');
      }

      // 解析 JSON-RPC 响应
      final jsonrpcResponse = jsonDecode(jsonData) as Map<String, dynamic>;

      // 检查错误
      if (jsonrpcResponse.containsKey('error')) {
        final error = jsonrpcResponse['error'];
        throw Exception('MCP tool error: ${error['message']}');
      }

      // 提取 result
      final result = jsonrpcResponse['result'];
      if (result == null) {
        throw Exception('MCP response missing "result" field');
      }

      // 解析 result.content
      return _parseToolResult(result);
    } catch (e) {
      throw Exception('Failed to parse SSE response: $e');
    }
  }

  /// 解析工具调用结果
  ///
  /// MCP 标准格式: { content: [{ type: "text", text: "..." }] }
  dynamic _parseToolResult(Map<String, dynamic> result) {
    try {
      final content = result['content'] as List<dynamic>?;
      if (content == null || content.isEmpty) {
        throw Exception('MCP result content is empty');
      }

      // 提取第一个 content 项的 text 字段
      final firstContent = content[0] as Map<String, dynamic>;
      final text = firstContent['text'] as String?;
      if (text == null) {
        throw Exception('MCP content missing "text" field');
      }

      // 尝试 JSON 解码（如果返回的是 JSON 字符串）
      try {
        return jsonDecode(text);
      } catch (e) {
        // 如果不是 JSON，直接返回文本
        return text;
      }
    } catch (e) {
      throw Exception('Failed to parse MCP tool result: $e');
    }
  }

  /// 将 MCP 菜谱数据转换为 Recipe 实体
  ///
  /// MCP 返回的数据格式与 Recipe 实体不完全匹配，需要进行字段映射和补充
  Recipe _mcpToRecipe(Map<String, dynamic> mcpData) {
    try {
      // 从 ID 中提取分类（如 "dishes-meat_dish-乡村啤酒鸭" -> "meat_dish"）
      // 如果没有 ID，则从 name 生成一个
      final id = mcpData['id'] as String? ??
                 'recipe_${(mcpData['name'] as String).hashCode.abs()}';
      final idParts = id.split('-');
      final category = idParts.length > 1 ? idParts[1] : 'unknown';

      // 分类名称映射
      final categoryNameMap = {
        'meat_dish': '荤菜',
        'vegetable_dish': '素菜',
        'breakfast': '早餐',
        'staple': '主食',
        'soup': '汤',
        'dessert': '甜品',
        'drink': '饮品',
        'semi-finished': '半成品加工',
        'condiment': '调料',
        'aquatic': '水产',
      };

      // 处理食材列表：MCP 使用 text_quantity，Recipe 期望 text
      final mcpIngredients = mcpData['ingredients'] as List<dynamic>? ?? [];
      final ingredients = mcpIngredients.map((item) {
        if (item is Map<String, dynamic>) {
          return {
            'name': item['name'] ?? '',
            'text': item['text_quantity'] ?? item['text'] ?? '',
          };
        }
        return {'name': '', 'text': item.toString()};
      }).toList();

      // 从 description 中提取步骤（简单处理：按行分割，过滤掉空行和标题）
      final description = mcpData['description'] as String? ?? '';
      final lines = description.split('\n').where((line) {
        final trimmed = line.trim();
        return trimmed.isNotEmpty &&
               !trimmed.startsWith('#') &&
               !trimmed.startsWith('!') &&
               !trimmed.startsWith('预估烹饪难度') &&
               !trimmed.startsWith('预计制作');
      }).toList();

      final steps = lines.isEmpty
          ? ['请参考菜谱详情']
          : lines.map((line) => line.trim()).toList();

      // 从 description 中提取难度（如 "预估烹饪难度：★★★★" -> 4）
      final difficultyMatch = RegExp(r'预估烹饪难度：(★+)').firstMatch(description);
      final difficulty = difficultyMatch != null
          ? difficultyMatch.group(1)!.length
          : 3;

      final recipeName = mcpData['name'] as String? ?? '未知菜谱';

      // 构建 Recipe JSON
      final recipeJson = {
        'id': id,
        'name': recipeName,
        'category': category,
        'categoryName': categoryNameMap[category] ?? '其他',
        'difficulty': difficulty,
        'images': [],
        'ingredients': ingredients,
        'tools': [],
        'steps': steps,
        'tips': null,
        'warnings': [],
        'hash': id.hashCode.toString(), // 使用 ID 的 hashCode 作为 hash
      };

      return Recipe.fromJson(recipeJson);
    } catch (e) {
      throw Exception('Failed to convert MCP data to Recipe: $e');
    }
  }

  /// 1. 获取所有菜谱
  ///
  /// 对应 MCP 工具: mcp_howtocook_getAllRecipes
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final result = await _callTool('getAllRecipes', {
        'no_param': '', // 工具要求的无参数标记
      });

      if (result is List) {
        return result.map((json) => _mcpToRecipe(json as Map<String, dynamic>)).toList();
      }

      throw Exception('Invalid getAllRecipes result format');
    } catch (e) {
      throw Exception('Failed to get all recipes: $e');
    }
  }

  /// 2. 按分类获取菜谱
  ///
  /// [category] 分类名称（中文：水产、早餐、调料、甜品、饮品、荤菜、半成品加工、汤、主食、素菜）
  /// 对应 MCP 工具: mcp_howtocook_getRecipesByCategory
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final result = await _callTool('getRecipesByCategory', {
        'category': category,
      });

      if (result is List) {
        return result.map((json) => _mcpToRecipe(json as Map<String, dynamic>)).toList();
      }

      throw Exception('Invalid getRecipesByCategory result format');
    } catch (e) {
      throw Exception('Failed to get recipes by category: $e');
    }
  }

  /// 3. 按名称或 ID 查询菜谱详情
  ///
  /// [query] 菜谱名称或 ID（支持模糊匹配）
  /// 对应 MCP 工具: mcp_howtocook_getRecipeById
  Future<Recipe> getRecipeById(String query) async {
    try {
      final result = await _callTool('getRecipeById', {
        'query': query,
      });

      if (result is Map<String, dynamic>) {
        // 检查是否是错误响应
        if (result.containsKey('error')) {
          throw Exception('MCP getRecipeById error: ${result['error']}');
        }

        return _mcpToRecipe(result);
      }

      throw Exception('Invalid getRecipeById result format');
    } catch (e) {
      throw Exception('Failed to get recipe by ID: $e');
    }
  }

  /// 4. 推荐菜谱
  ///
  /// [peopleCount] 用餐人数（1-10）
  /// [allergies] 过敏原列表（可选）
  /// [avoidItems] 忌口食材列表（可选）
  /// 对应 MCP 工具: mcp_howtocook_recommendMeals
  Future<Map<String, dynamic>> recommendMeals({
    required int peopleCount,
    List<String>? allergies,
    List<String>? avoidItems,
  }) async {
    try {
      final arguments = <String, dynamic>{
        'peopleCount': peopleCount,
      };

      if (allergies != null && allergies.isNotEmpty) {
        arguments['allergies'] = allergies;
      }

      if (avoidItems != null && avoidItems.isNotEmpty) {
        arguments['avoidItems'] = avoidItems;
      }

      final result = await _callTool('recommendMeals', arguments);

      if (result is Map<String, dynamic>) {
        return result;
      }

      throw Exception('Invalid recommendMeals result format');
    } catch (e) {
      throw Exception('Failed to recommend meals: $e');
    }
  }

  /// 5. 今天吃什么
  ///
  /// [peopleCount] 用餐人数（1-10）
  /// 对应 MCP 工具: mcp_howtocook_whatToEat
  /// 返回格式: { peopleCount, meatDishCount, vegetableDishCount, dishes: [...], message }
  Future<List<Recipe>> whatToEat({required int peopleCount}) async {
    try {
      final result = await _callTool('whatToEat', {
        'peopleCount': peopleCount,
      });

      if (result is Map<String, dynamic>) {
        // 提取 dishes 数组
        final dishes = result['dishes'] as List<dynamic>?;
        if (dishes == null) {
          throw Exception('whatToEat result missing "dishes" field');
        }

        // 使用 _mcpToRecipe 转换 MCP 数据为 Recipe 实体
        return dishes.map((json) => _mcpToRecipe(json as Map<String, dynamic>)).toList();
      }

      throw Exception('Invalid whatToEat result format');
    } catch (e) {
      throw Exception('Failed to get what to eat: $e');
    }
  }

  /// 搜索菜谱（通过 getAllRecipes 然后本地过滤）
  ///
  /// [query] 搜索关键词
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final allRecipes = await getAllRecipes();

      // 本地过滤
      final results = allRecipes.where((recipe) {
        return recipe.name.contains(query) ||
               recipe.categoryName.contains(query) ||
               (recipe.tips?.contains(query) ?? false);
      }).toList();

      return results;
    } catch (e) {
      throw Exception('Failed to search recipes: $e');
    }
  }

  /// 获取随机菜谱（通过 whatToEat）
  ///
  /// [count] 数量（通过 peopleCount 参数控制）
  Future<List<Recipe>> getRandomRecipes({int count = 5}) async {
    // whatToEat 使用 peopleCount，我们用它来近似控制数量
    return whatToEat(peopleCount: count.clamp(1, 10));
  }

  /// 获取菜谱详情（通过 getRecipeById）
  ///
  /// [recipeId] 菜谱 ID 或名称
  /// 注意：如果传入的是通过 getAllRecipes 生成的 ID（格式：recipe_xxx），
  /// 则无法查询详情。建议使用菜谱名称进行查询。
  Future<Recipe> getRecipeDetail(String recipeId) async {
    // 检查是否是生成的 ID
    if (recipeId.startsWith('recipe_')) {
      throw Exception(
        'Generated ID cannot be used for detail query. '
        'Please use recipe name instead. '
        'Generated IDs are only from getAllRecipes which returns minimal data.',
      );
    }
    return getRecipeById(recipeId);
  }

  /// 获取收藏的菜谱（通过多次调用 getRecipeById）
  ///
  /// [favoriteIds] 收藏的菜谱 ID 列表
  Future<List<Recipe>> getFavoriteRecipes(List<String> favoriteIds) async {
    try {
      final recipes = <Recipe>[];

      // 并发获取所有收藏的菜谱
      final futures = favoriteIds.map((id) => getRecipeById(id));
      final results = await Future.wait(
        futures,
        eagerError: false,
      );

      recipes.addAll(results);
      return recipes;
    } catch (e) {
      throw Exception('Failed to get favorite recipes: $e');
    }
  }

  /// 健康检查
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Health check failed: $e');
    }
  }

  /// 获取服务器信息
  Future<Map<String, dynamic>> getServerInfo() async {
    try {
      final response = await _dio.get('/info');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get server info: $e');
    }
  }

  /// 6. 创建新食谱
  ///
  /// [recipeText] 自然语言格式的食谱文本
  /// [checkDuplicate] 是否检查重复（默认 true）
  /// [similarityThreshold] 相似度检测阈值（0-1，默认 0.75）
  /// 对应 MCP 工具: mcp_howtocook_createRecipe
  ///
  /// 返回格式: {
  ///   recipe: {...},  // 创建的食谱对象
  ///   warnings: [...] // 警告信息（如相似度检测结果）
  /// }
  Future<Map<String, dynamic>> createRecipe({
    required String recipeText,
    bool checkDuplicate = true,
    double similarityThreshold = 0.75,
  }) async {
    try {
      final arguments = <String, dynamic>{
        'recipeText': recipeText,
        'checkDuplicate': checkDuplicate,
        'similarityThreshold': similarityThreshold,
      };

      final result = await _callTool('createRecipe', arguments);

      if (result is Map<String, dynamic>) {
        // 检查是否有错误
        if (result.containsKey('error')) {
          throw Exception('创建食谱失败: ${result['error']}');
        }

        return result;
      }

      throw Exception('Invalid createRecipe result format');
    } catch (e) {
      throw Exception('Failed to create recipe: $e');
    }
  }

  /// 获取可用的工具列表
  Future<List<Map<String, dynamic>>> listTools() async {
    try {
      _requestId++;

      final requestData = {
        'jsonrpc': '2.0',
        'id': _requestId,
        'method': 'tools/list',
      };

      final response = await _dio.post(
        '/mcp',
        data: requestData,
      );

      // tools/list 返回格式特殊，需要单独解析
      final data = response.data as String;
      final lines = data.split('\n');
      String? jsonData;

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          jsonData = line.substring(6);
          break;
        }
      }

      if (jsonData == null) {
        throw Exception('No data found in SSE response');
      }

      final jsonrpcResponse = jsonDecode(jsonData) as Map<String, dynamic>;

      if (jsonrpcResponse.containsKey('error')) {
        final error = jsonrpcResponse['error'];
        throw Exception('MCP error: ${error['message']}');
      }

      final result = jsonrpcResponse['result'] as Map<String, dynamic>?;
      if (result == null) {
        throw Exception('MCP response missing result field');
      }

      final tools = result['tools'] as List<dynamic>?;
      if (tools == null) {
        throw Exception('MCP response missing tools field');
      }

      return tools.map((tool) => tool as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to list tools: $e');
    }
  }
}
