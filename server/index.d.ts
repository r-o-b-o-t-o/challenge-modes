declare interface Aio {
	AddHandlers: (this: void, name: string, handlerTable: object) => Object,
	Handle: (this: void, player: Player, channel: string, handlerName: string, ...args) => void,
}
