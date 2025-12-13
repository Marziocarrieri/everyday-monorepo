class ShoppingItem {
  final String id;
  final String householdId;
  final String name;
  final int quantity;
  final String status; // 'PENDING', 'BOUGHT'

  ShoppingItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.quantity,
    required this.status,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      householdId: json['household_id'],
      name: json['name'],
      quantity: json['quantity'] ?? 1,  //quell' 1 vuol dire che se la quantità non è specificata, sarà 1
      status: json['status'] ?? 'PENDING', //PENDING vuol dire "da comprare", in modo da avere tre stati invece che due 
    );
  }
}