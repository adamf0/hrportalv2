import 'dart:async';

abstract class IRequest<T> {}

abstract class ICommand<T> extends IRequest<T> {}

abstract class IQuery<T> extends IRequest<T> {}

abstract class IRequestHandler<R extends IRequest<T>, T> {
  Future<T> handle(R request);
}

abstract class ICommandHandler<C extends ICommand<T>, T> implements IRequestHandler<C, T> {}

abstract class IQueryHandler<Q extends IQuery<T>, T> implements IRequestHandler<Q, T> {}

class Mediator {
  static final Mediator _instance = Mediator._internal();
  factory Mediator() => _instance;
  Mediator._internal();

  final Map<Type, dynamic> _handlers = {};

  void registerHandler<R extends IRequest<T>, T>(IRequestHandler<R, T> handler) {
    _handlers[R] = handler;
  }

  Future<T> send<T>(IRequest<T> request) async {
    final type = request.runtimeType;
    final handler = _handlers[type];
    if (handler == null) {
      throw Exception('No handler registered for request type $type');
    }
    return await (handler as IRequestHandler<IRequest<T>, T>).handle(request);
  }
}
