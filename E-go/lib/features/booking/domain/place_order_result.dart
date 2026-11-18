// Result of the exactly-once place-order operation.

enum PlaceOrderStatus { success, invalid, inProgress, failure }

class PlaceOrderResult {
  const PlaceOrderResult._(this.status, {this.orderId, this.message});

  const PlaceOrderResult.success(String orderId)
    : this._(PlaceOrderStatus.success, orderId: orderId);

  const PlaceOrderResult.inProgress(String? orderId)
    : this._(
        PlaceOrderStatus.inProgress,
        orderId: orderId,
        message: 'Your order is already being placed.',
      );

  const PlaceOrderResult.invalid(String message)
    : this._(PlaceOrderStatus.invalid, message: message);

  const PlaceOrderResult.failure(String message)
    : this._(PlaceOrderStatus.failure, message: message);

  final PlaceOrderStatus status;
  final String? orderId;
  final String? message;

  bool get isSuccess => status == PlaceOrderStatus.success;
}
