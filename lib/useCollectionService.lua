local CollectionService = game:GetService("CollectionService")
local Package = script.Parent
local Matter = require(Package.Parent.Matter)
local Queue = require(Package.Queue)

export type collectionServiceTagAddedEvent = {
	instance: Instance,
	added: true,
	removed: false,
}
export type collectionServiceTagRemovedEvent = {
	instance: Instance,
	added: false,
	removed: true,
}

export type collectionServiceTagEvent =
	collectionServiceTagAddedEvent
	| collectionServiceTagRemovedEvent

local function collectionServiceTagAddedEvent(instance: Instance): collectionServiceTagAddedEvent
	return {
		instance = instance,
		added = true,
		removed = false,
	}
end

local function collectionServiceTagRemovedEvent(
	instance: Instance
): collectionServiceTagRemovedEvent
	return {
		instance = instance,
		added = false,
		removed = true,
	}
end

local function cleanup(storage): ()
	storage.addedConnection:Disconnect()
	storage.removedConnection:Disconnect()
end

local function useCollectionService(tagName: string): (() -> (number?, collectionServiceTagEvent))
	local storage = Matter.useHookState(tagName, cleanup)

	if not storage.queue then
		storage.queue = Queue.new()

		for _, instance: Instance in CollectionService:GetTagged(tagName) do
			storage.queue:push(collectionServiceTagAddedEvent(instance))
		end

		storage.addedConnection = CollectionService:GetInstanceAddedSignal(tagName)
			:Connect(function(instance: Instance)
				storage.queue:push(collectionServiceTagAddedEvent(instance))
			end)
		storage.removedConnection = CollectionService:GetInstanceRemovedSignal(tagName)
			:Connect(function(instance: Instance)
				storage.queue:push(collectionServiceTagRemovedEvent(instance))
			end)
	end

	local index: number = 0
	return function(): (number?, collectionServiceTagEvent)
		index += 1

		local value: collectionServiceTagEvent? = storage.queue:shift()

		if value then
			return index, value
		end

		return nil, (nil :: unknown) :: collectionServiceTagEvent
	end
end

return useCollectionService
