@startuml
title PlasticProphet - Physical View (AWS Serverless)

node "User Device (iOS/Android)" as Phone {
  artifact "Mobile App"
  component "Card Scanner"
  component "Geofence Agent"
  component "Push SDK"
}

node "CDN/Edge" as CDN

node "AWS Cloud" {
  node "Serverless APIs" {
    component "Amazon API Gateway" as APIGW
    component "Amazon Cognito User Pool" as Cognito
  }

  node "Lambda Functions" {
    component "RecommendationFn" as RecFn
    component "UserProfileFn" as UserFn
    component "CardCatalogFn" as CardFn
    component "MerchantResolverFn" as MerchFn
    component "CardTypeResolverFn" as BinFn
    component "PrivacyFn" as PrivacyFn
    component "AnalyticsIngestFn" as AnalyticsFn
    component "BonusScraperFn" as BonusFn
  }

  node "Data Stores" {
    database "DynamoDB: Users" as DDBUsers
    database "DynamoDB: CardsRules" as DDBCards
    database "DynamoDB: BinDirectory" as DDBBin
    database "DynamoDB: Cache/TTL" as DDBCache
    node "S3" {
      database "Events/Logs" as S3Logs
    }
  }

  node "Eventing & Messaging" {
    component "EventBridge Bus" as Bus
    component "EventBridge Scheduler" as Sched
    component "Amazon Pinpoint / SNS" as Notify
    component "Kinesis Firehose" as Firehose
  }
}

node "External" {
  node "APNs / FCM" as PushNet
  node "Mastercard Places" as MCPlaces
  node "Apple / Google Identity" as OIDC
}

"Mobile App" -- CDN
CDN -- APIGW
"Push SDK" ..> PushNet

' Auth
"Mobile App" ..> Cognito
Cognito ..> OIDC

' API
@enduml