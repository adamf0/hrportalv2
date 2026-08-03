package domain

type IDomainEvent interface {
	IsDomainEvent()
}

type Entity struct {
	domainEvents []IDomainEvent
}

func NewEntity() *Entity {
	return &Entity{
		domainEvents: []IDomainEvent{},
	}
}

func (e *Entity) DomainEvents() []IDomainEvent {
	eventsCopy := make([]IDomainEvent, len(e.domainEvents))
	copy(eventsCopy, e.domainEvents)
	return eventsCopy
}

func (e *Entity) ClearDomainEvents() {
	e.domainEvents = []IDomainEvent{}
}

func (e *Entity) Raise(event IDomainEvent) {
	e.domainEvents = append(e.domainEvents, event)
}
