from django.urls import path
from . import views
from rest_framework_simplejwt.views import (
    TokenRefreshView,
)
urlpatterns = [
    path('register/', views.registerUser.as_view()),
    path('login/', views.loginUser.as_view()),
    path('token/', views.TokenObtainPairWithEmailView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]