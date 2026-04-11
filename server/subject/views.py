from .models import Subject
from .serializer import SubjectSerializer
from authentication.models import User
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.tokens import AccessToken


def _get_current_user_from_token(request):
    """Resolve the custom authentication.User from the JWT in the Authorization header."""
    auth_header = request.headers.get('Authorization') or request.META.get('HTTP_AUTHORIZATION', '')
    if not auth_header.startswith('Bearer '):
        raise AuthenticationFailed('Authentication credentials were not provided.')

    raw_token = auth_header.split(' ', 1)[1].strip()
    try:
        token = AccessToken(raw_token)
    except Exception:
        raise AuthenticationFailed('Token is invalid or expired.')

    user_id = token.get('user_id')
    if user_id is None:
        raise AuthenticationFailed('Invalid token payload.')

    try:
        return User.objects.get(id=user_id)
    except User.DoesNotExist:
        raise AuthenticationFailed('User not found.')


class SubjectListCreateView(generics.ListCreateAPIView):
    serializer_class = SubjectSerializer
    # Disable DRF's default JWT auth and do manual JWT -> authentication.User
    authentication_classes = []
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        user = _get_current_user_from_token(self.request)
        # Teachers see subjects they own; students see subjects they are enrolled in
        if getattr(user, 'account_type', '').upper() == 'TEACHER':
            return Subject.objects.filter(owner=user)
        return Subject.objects.filter(enrolled_students=user)

    def perform_create(self, serializer):
        # only teachers may create subjects
        user = _get_current_user_from_token(self.request)
        if getattr(user, 'account_type', '').upper() != 'TEACHER':
            raise AuthenticationFailed('Only teachers can create subjects.')
        serializer.save(owner=user)

    # override post to return proper response when non-teacher tries to create
    def post(self, request, *args, **kwargs):
        user = _get_current_user_from_token(request)
        if getattr(user, 'account_type', '').upper() != 'TEACHER':
            return Response({'detail': 'Only teachers can create subjects.'}, status=status.HTTP_403_FORBIDDEN)
        return super().post(request, *args, **kwargs)


class SubjectDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Subject.objects.all()
    serializer_class = SubjectSerializer
    authentication_classes = []
    permission_classes = [permissions.AllowAny]

    def get(self, request, *args, **kwargs):
        user = _get_current_user_from_token(request)
        subject = self.get_object()
        # allow owner or enrolled students to view details
        if user != subject.owner and user not in subject.enrolled_students.all():
            return Response({'detail': 'You are not enrolled in this subject.'}, status=status.HTTP_403_FORBIDDEN)
        return Response(self.serializer_class(subject).data, status=status.HTTP_200_OK)

    def put(self, request, *args, **kwargs):
        user = _get_current_user_from_token(request)
        subject = self.get_object()
        if subject.owner != user:
            return Response({'detail': 'Only the owner can update this subject.'}, status=status.HTTP_403_FORBIDDEN)
        return super().put(request, *args, **kwargs)

    def patch(self, request, *args, **kwargs):
        user = _get_current_user_from_token(request)
        subject = self.get_object()
        if subject.owner != user:
            return Response({'detail': 'Only the owner can update this subject.'}, status=status.HTTP_403_FORBIDDEN)
        return super().patch(request, *args, **kwargs)

    def delete(self, request, *args, **kwargs):
        user = _get_current_user_from_token(request)
        subject = self.get_object()
        if subject.owner != user:
            return Response({'detail': 'Only the owner can delete this subject.'}, status=status.HTTP_403_FORBIDDEN)
        return super().delete(request, *args, **kwargs)


class SubjectEnrollView(APIView):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk, *args, **kwargs):
        user = _get_current_user_from_token(request)
        # enroll the requesting user in the subject
        try:
            subject = Subject.objects.get(pk=pk)
        except Subject.DoesNotExist:
            return Response({'detail': 'Subject not found.'}, status=status.HTTP_404_NOT_FOUND)
        if subject.is_completed:
            return Response({'detail': 'This subject is completed and cannot be joined.'}, status=status.HTTP_400_BAD_REQUEST)
        if user == subject.owner:
            return Response({'detail': 'Owner is already part of the subject.'}, status=status.HTTP_400_BAD_REQUEST)
        subject.enrolled_students.add(user)
        return Response({'detail': 'You have been enrolled in this subject.'}, status=status.HTTP_200_OK)

    def delete(self, request, pk, *args, **kwargs):
        user = _get_current_user_from_token(request)
        # unenroll the requesting user from the subject
        try:
            subject = Subject.objects.get(pk=pk)
        except Subject.DoesNotExist:
            return Response({'detail': 'Subject not found.'}, status=status.HTTP_404_NOT_FOUND)
        if user not in subject.enrolled_students.all():
            return Response({'detail': 'You are not enrolled in this subject.'}, status=status.HTTP_400_BAD_REQUEST)
        subject.enrolled_students.remove(user)
        return Response({'detail': 'You have been unenrolled from this subject.'}, status=status.HTTP_200_OK)