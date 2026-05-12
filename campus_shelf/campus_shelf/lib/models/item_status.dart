enum ItemStatus {
  available,
  pendingMeetup,
  sold,
}

extension ItemStatusExtension on ItemStatus {
  String get value => toString().split('.').last;

  static ItemStatus fromString(String status) {
    switch (status) {
      case 'available':
        return ItemStatus.available;
      case 'pendingMeetup':
        return ItemStatus.pendingMeetup;
      case 'sold':
        return ItemStatus.sold;
      default:
        return ItemStatus.available;
    }
  }
}
