import '../repositories/task_repository.dart';

class TaskAssignmentService {
  final TaskRepository _repo = TaskRepository();

  // Assegnazione di un task
  Future<void> assignTask(String taskId, String memberId) async {
    await _repo.assignTask(taskId, memberId);
  }

  // Assegna come fatto
  Future<void> markAsDone(String assignmentId) async {
    // Ordiniamo al repository di impostare lo stato su 'DONE'
    await _repo.updateAssignmentStatus(assignmentId, 'DONE');
  }

  // salta il task (Opzionale)
  // Future<void> skipTask(String assignmentId) async {
    // await _repo.updateAssignmentStatus(assignmentId, 'SKIPPED');
  // }
}