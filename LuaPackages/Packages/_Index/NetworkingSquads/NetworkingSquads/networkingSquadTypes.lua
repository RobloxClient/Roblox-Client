--!strict
export type Config = {
	roduxNetworking: any,
	useMockedResponse: boolean,
}

export type Squad = {
	squadId: string,
	members: { [number]: number },
}

export type CreateSquadRequest = {
	userIds: { [number]: number },
}

export type CreateSquadResponse = {
	squad: Squad,
}

export type GetSquadFromSquadIdRequest = {
	squadId: string,
}

export type GetSquadFromSquadIdResponse = {
	squad: Squad,
}

export type JoinSquadRequest = {
	squadId: string,
}

export type JoinSquadResponse = {
	squad: Squad,
}

export type LeaveSquadRequest = {
	squadId: string,
}

export type SquadInviteRequest = {
	squadId: string,
	inviteeUserIds: { number },
}

export type SquadRemoveRequest = {
	squadId: string,
	userIdToRemove: number,
}

export type SquadRemoveResponse = {
	squad: Squad,
}

export type CreateExperienceInviteRequest = {
	squadId: string,
	universeId: string,
}

export type GetExperienceInviteRequest = {
	inviteId: number,
}

export type RespondExperienceInviteRequest = {
	inviteId: number,
	response: string,
}

export type RequestThunks = {
	CreateSquad: CreateSquadRequest,
	GetSquadFromSquadId: GetSquadFromSquadIdRequest,
	JoinSquad: JoinSquadRequest,
	LeaveSquad: LeaveSquadRequest,
	SquadInvite: SquadInviteRequest,
	SquadRemove: SquadRemoveRequest,
	CreateExperienceInvite: CreateExperienceInviteRequest,
	GetExperienceInvite: GetExperienceInviteRequest,
	RespondExperienceInvite: RespondExperienceInviteRequest,
}

return {}
