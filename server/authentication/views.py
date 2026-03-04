from rest_framework import generics, status
from rest_framework.response import Response
from .models import User
from .serializer import UserSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework.exceptions import AuthenticationFailed


class TokenObtainPairWithEmailSerializer(TokenObtainPairSerializer):
    # Tell the parent serializer to use `email` as the username field
    username_field = 'email'
    def validate(self, attrs):
        # Expecting `email` and `password` in the request body
        email = attrs.get('email') or attrs.get(self.username_field)
        password = attrs.get('password')

        if not email or not password:
            raise AuthenticationFailed('Email and password are required')

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise AuthenticationFailed('No active account found with the given credentials')

        # NOTE: this project stores passwords in plain text in the `password` field.
        # For production, use Django's `make_password` and `check_password` or AbstractUser.
        if user.password != password:
            raise AuthenticationFailed('Invalid email or password')

        refresh = self.get_token(user)

        data = {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }

        # Include basic user info in response
        data['user'] = UserSerializer(user).data
        return data


class TokenObtainPairWithEmailView(TokenObtainPairView):
    serializer_class = TokenObtainPairWithEmailSerializer

class registerUser(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
class loginUser(generics.GenericAPIView):
    serializer_class = UserSerializer

    def post(self, request, *args, **kwargs):
        email = request.data.get('email')
        password = request.data.get('password')
        try:
            user = User.objects.get(email=email, password=password)
            serializer = self.get_serializer(user)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'Invalid email or password'}, status=status.HTTP_401_UNAUTHORIZED)