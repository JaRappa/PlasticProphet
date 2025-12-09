@startuml
title PlasticProphet - Logical View
skinparam style strictuml

' --- diagram type declaration (class) ---
!define RECTANGLE class

RECTANGLE MobileApp {
  +openHome()
  +showRecommendation()
}

RECTANGLE OnboardingFlow {
  +start()
  +acceptTos()
  +addCards()
}

RECTANGLE PermissionsManager {
  +requestCamera()
  +requestLocation()
}

RECTANGLE CardScanner {
  +scanFrontDigits(): String
}

interface ILocationProvider {
  +currentLatLon(): Geo
  +startGeofencing()
}

RECTANGLE GeofenceAgent
RECTANGLE NotificationAgent {
  +pushLocal(msg)
  +handleRemote(payload)
}

RECTANGLE RecommendationFacade {
  +getBestCard(userId, geo): Recommendation
}

RECTANGLE RecommendationService {
  +recommend(user, merchant, cards): Recommendation
  -scoreOptions(user, merchant, cards): ScoreList
}

RECTANGLE RulesEngine {
  +evaluate(merchant, card, user): Score
}

RECTANGLE CardCatalog {
  +listCards(userId): CardList
  +getRules(cardId): RuleSet
}

RECTANGLE CardTypeResolver {
  +fromBin(binDigits): CardSuggestionList
}

RECTANGLE MerchantResolver {
  +fromGeo(geo): Merchant
}

RECTANGLE BonusFeedService {
  +activeBonuses(): BonusList
}

RECTANGLE UserProfile {
  +get(userId): User
}

RECTANGLE AuthManager {
  +login()
  +refresh()
}

RECTANGLE PrivacyManager {
  +deleteAccount(userId)
}

RECTANGLE Analytics {
  +log(event, payload)
}

' --- simple data holders ---
RECTANGLE Merchant
RECTANGLE Card
RECTANGLE CardSuggestionList
RECTANGLE Recommendation
RECTANGLE User
RECTANGLE RuleSet
RECTANGLE Geo
RECTANGLE Score
RECTANGLE CardList
RECTANGLE ScoreList
RECTANGLE BonusList

' --- relationships ---
MobileApp --> OnboardingFlow
OnboardingFlow --> PermissionsManager
OnboardingFlow --> CardScanner
OnboardingFlow --> CardTypeResolver
MobileApp --> GeofenceAgent
MobileApp --> NotificationAgent
MobileApp --> RecommendationFacade
MobileApp --> AuthManager
MobileApp --> PrivacyManager

RecommendationFacade --> RecommendationService
RecommendationService --> RulesEngine
RecommendationService --> CardCatalog
RecommendationService --> UserProfile
RecommendationService --> MerchantResolver
RecommendationService --> BonusFeedService
RecommendationService --> Analytics

GeofenceAgent -|> ILocationProvider
@enduml
