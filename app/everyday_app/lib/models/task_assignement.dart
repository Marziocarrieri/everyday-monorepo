import 'household_member.dart'; // Importiamo il membro perché è la persona assegnata

class TaskAssignment {
  final String id;
  final String taskId;
  final String memberId;
  final String status; // 'TODO', 'DONE', 'SKIPPED'
  final DateTime? completedAt;
  final HouseholdMember? member; // Dettagli di chi lo deve fare

  TaskAssignment({
    required this.id,
    required this.taskId,
    required this.memberId,
    required this.status,
    this.completedAt,
    this.member,
  });

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    return TaskAssignment(
      id: json['id'],
      taskId: json['task_id'],
      memberId: json['member_id'],
      status: json['status'] ?? 'TODO',
      
      // La data di completamento è opzionale
      //completedAt: json['completed_at'] != null 
         // ? DateTime.parse(json['completed_at']) 
          // : null,
          
      // Convertiamo il membro se presente nella query (JOIN)
      member: json['household_member'] != null 
          ? HouseholdMember.fromJson(json['household_member']) 
          : null,
    );
  }
}