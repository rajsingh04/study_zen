from rest_framework import generics, permissions, status
from rest_framework.exceptions import AuthenticationFailed
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import AccessToken

from authentication.models import User
from subject.models import Subject

from .models import Material
from .serializer import MaterialSerializer


def _get_current_user_from_token(request):
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


class MaterialListCreateView(generics.ListCreateAPIView):
	serializer_class = MaterialSerializer
	authentication_classes = []
	permission_classes = [permissions.AllowAny]

	def get_queryset(self):
		user = _get_current_user_from_token(self.request)
		subject_id = self.request.query_params.get('subject') or self.request.query_params.get('subject_id')
		qs = Material.objects.all()
		if subject_id:
			qs = qs.filter(subject_id=subject_id)

		if getattr(user, 'account_type', '').upper() == 'TEACHER':
			return qs.filter(owner=user)
		return qs.filter(subject__enrolled_students=user)

	def perform_create(self, serializer):
		user = _get_current_user_from_token(self.request)
		if getattr(user, 'account_type', '').upper() != 'TEACHER':
			raise AuthenticationFailed('Only teachers can create materials.')

		subject_id = self.request.data.get('subject') or self.request.data.get('subject_id')
		if not subject_id:
			raise AuthenticationFailed('Subject must be provided when creating a material.')

		try:
			subject = Subject.objects.get(pk=subject_id)
		except Subject.DoesNotExist:
			return Response({'detail': 'Subject not found.'}, status=status.HTTP_404_NOT_FOUND)

		if subject.owner != user:
			raise AuthenticationFailed('You are not the owner of the subject.')

		serializer.save(owner=user, subject=subject)

	def post(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		if getattr(user, 'account_type', '').upper() != 'TEACHER':
			return Response({'detail': 'Only teachers can create materials.'}, status=status.HTTP_403_FORBIDDEN)
		return super().post(request, *args, **kwargs)


class MaterialDetailView(generics.RetrieveUpdateDestroyAPIView):
	queryset = Material.objects.all()
	serializer_class = MaterialSerializer
	authentication_classes = []
	permission_classes = [permissions.AllowAny]

	def get(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		material = self.get_object()
		if user != material.owner and user not in material.subject.enrolled_students.all():
			return Response({'detail': 'You are not enrolled in this subject.'}, status=status.HTTP_403_FORBIDDEN)
		return Response(self.serializer_class(material).data, status=status.HTTP_200_OK)

	def put(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		material = self.get_object()
		if material.owner != user:
			return Response({'detail': 'Only the owner can update this material.'}, status=status.HTTP_403_FORBIDDEN)
		return super().put(request, *args, **kwargs)

	def patch(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		material = self.get_object()
		if material.owner != user:
			return Response({'detail': 'Only the owner can update this material.'}, status=status.HTTP_403_FORBIDDEN)
		return super().patch(request, *args, **kwargs)

	def delete(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		material = self.get_object()
		if material.owner != user:
			return Response({'detail': 'Only the owner can delete this material.'}, status=status.HTTP_403_FORBIDDEN)
		return super().delete(request, *args, **kwargs)
