import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/conversation.dart';
import '../../infrastructure/repositories/conversation_repository.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository();
});

final conversationListProvider =
    StateNotifierProvider<ConversationListNotifier, AsyncValue<List<Conversation>>>((ref) {
  final repo = ref.watch(conversationRepositoryProvider);
  return ConversationListNotifier(repo);
});

final activeConversationIdProvider = StateProvider<String?>((ref) => null);

class ConversationListNotifier extends StateNotifier<AsyncValue<List<Conversation>>> {
  final ConversationRepository _repo;

  ConversationListNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getAll();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Conversation> createConversation({String title = '新对话'}) async {
    final conv = _repo.createNew(title: title);
    await _repo.save(conv);
    await load();
    return conv;
  }

  Future<void> updateConversation(Conversation conversation) async {
    await _repo.save(conversation);
    await load();
  }

  Future<void> deleteConversation(String id) async {
    await _repo.delete(id);
    await load();
  }
}
