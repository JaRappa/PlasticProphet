@startuml
title Process - Geofence Recommendation (AWS Serverless)

actor User
participant "Mobile App" as App
participant "Geofence Agent" as Geo
participant "Amazon API Gateway" as APIGW
participant "Lambda: RecommendationFn" as RecFn
participant "Lambda: MerchantResolverFn" as MerchFn
database "DynamoDB: Users" as DDBUsers
database "DynamoDB: CardsRules" as DDBCards
participant "Rules Engine (in RecFn)" as Rules
participant "Notification Agent" as Notif
participant "Mastercard Places" as MCPlaces

User -> Geo: enter region
Geo -> App: geofenceEvent(lat, lon)
App -> APIGW: GET /recommendations?geo
APIGW -> RecFn: invoke with userId, geo
RecFn -> MerchFn: invoke fromGeo(geo)
MerchFn -> MCPlaces: lookup merchant by lat/lon
MCPlaces --> MerchFn: merchant
MerchFn --> RecFn: merchant
RecFn -> DDBUsers: get user profile
DDBUsers --> RecFn: user
RecFn -> DDBCards: get cards + rules
DDBCards --> RecFn: cards, rules
RecFn -> Rules: evaluate per card
Rules --> RecFn: bestCard, rationale, reward
RecFn --> APIGW: response payload
APIGW --> App: 200 bestCard
App -> Notif: local notification
Notif -> User: "Use Card X for Y back"
@enduml