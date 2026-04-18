from .models import Assignment, Submission
from .serializer import AssignmentSerializer, SubmissionSerializer
from authentication.models import User
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.tokens import AccessToken
from django.http import HttpResponse


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


class AssignmentListCreateView(generics.ListCreateAPIView):
	serializer_class = AssignmentSerializer
	authentication_classes = []
	permission_classes = [permissions.AllowAny]

	def get_queryset(self):
		user = _get_current_user_from_token(self.request)
		# Optionally filter by subject via query param
		subject_id = self.request.query_params.get('subject') or self.request.query_params.get('subject_id')
		qs = Assignment.objects.all()
		if subject_id:
			qs = qs.filter(subject_id=subject_id)

		# Teachers by default see only assignments they created; students see assignments for subjects they are enrolled in
		if getattr(user, 'account_type', '').upper() == 'TEACHER':
			return qs.filter(owner=user)
		# student: limit to assignments for subjects the student is enrolled in
		return qs.filter(subject__enrolled_students=user)

	def perform_create(self, serializer):
		user = _get_current_user_from_token(self.request)
		if getattr(user, 'account_type', '').upper() != 'TEACHER':
			raise AuthenticationFailed('Only teachers can create assignments.')
		# validate subject ownership
		subject = None
		subject_id = self.request.data.get('subject') or self.request.data.get('subject_id')
		if not subject_id:
			raise AuthenticationFailed('Subject must be provided when creating an assignment.')
		from subject.models import Subject
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
			return Response({'detail': 'Only teachers can create assignments.'}, status=status.HTTP_403_FORBIDDEN)
		return super().post(request, *args, **kwargs)


class AssignmentDetailView(generics.RetrieveUpdateDestroyAPIView):
	queryset = Assignment.objects.all()
	serializer_class = AssignmentSerializer
	authentication_classes = []
	permission_classes = [permissions.AllowAny]

	def get(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		assignment = self.get_object()
		# allow owner (teacher) or enrolled students to view
		if user != assignment.owner and user not in assignment.subject.enrolled_students.all():
			return Response({'detail': 'You are not enrolled in this subject.'}, status=status.HTTP_403_FORBIDDEN)
		return Response(self.serializer_class(assignment).data, status=status.HTTP_200_OK)

	def put(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		assignment = self.get_object()
		if assignment.owner != user:
			return Response({'detail': 'Only the owner can update this assignment.'}, status=status.HTTP_403_FORBIDDEN)
		return super().put(request, *args, **kwargs)

	def patch(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		assignment = self.get_object()
		if assignment.owner != user:
			return Response({'detail': 'Only the owner can update this assignment.'}, status=status.HTTP_403_FORBIDDEN)
		return super().patch(request, *args, **kwargs)

	def delete(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		assignment = self.get_object()
		if assignment.owner != user:
			return Response({'detail': 'Only the owner can delete this assignment.'}, status=status.HTTP_403_FORBIDDEN)
		return super().delete(request, *args, **kwargs)


class SubmissionListCreateView(APIView):
	"""List submissions for an assignment (teacher sees all, student sees their own)
	and allow students to create (upload) a submission."""

	authentication_classes = []
	permission_classes = [permissions.AllowAny]

	def get(self, request, pk, *args, **kwargs):
		user = _get_current_user_from_token(request)
		try:
			assignment = Assignment.objects.get(pk=pk)
		except Assignment.DoesNotExist:
			return Response({'detail': 'Assignment not found.'}, status=status.HTTP_404_NOT_FOUND)

		# NOTE: Submissions store files as a Postgres blob. Avoid fetching file_blob
		# for list endpoints; it can be very large and slow.
		if getattr(user, 'account_type', '').upper() == 'TEACHER':
			if assignment.owner != user:
				return Response({'detail': 'Only the owner can view submissions.'}, status=status.HTTP_403_FORBIDDEN)
			submissions = assignment.submissions.select_related('student').defer('file_blob').all()
		else:
			submissions = assignment.submissions.select_related('student').defer('file_blob').filter(student=user)

		serializer = SubmissionSerializer(submissions, many=True, context={"request": request})
		return Response(serializer.data, status=status.HTTP_200_OK)

	def post(self, request, pk, *args, **kwargs):
		user = _get_current_user_from_token(request)
		if getattr(user, 'account_type', '').upper() == 'TEACHER':
			return Response({'detail': 'Only students can submit assignments.'}, status=status.HTTP_403_FORBIDDEN)

		try:
			assignment = Assignment.objects.get(pk=pk)
		except Assignment.DoesNotExist:
			return Response({'detail': 'Assignment not found.'}, status=status.HTTP_404_NOT_FOUND)

		serializer = SubmissionSerializer(data=request.data, context={"request": request})
		if serializer.is_valid():
			serializer.save(student=user, assignment=assignment)
			return Response(serializer.data, status=status.HTTP_201_CREATED)
		return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SubmissionFileDownloadView(APIView):
	"""Download the submitted file stored as a Postgres blob."""

	authentication_classes = []
	permission_classes = [permissions.AllowAny]

	def get(self, request, pk, *args, **kwargs):
		user = _get_current_user_from_token(request)
		try:
			submission = Submission.objects.select_related("assignment", "student").get(pk=pk)
		except Submission.DoesNotExist:
			return Response({"detail": "Submission not found."}, status=status.HTTP_404_NOT_FOUND)

		# teacher owner of the assignment or the student may download
		if submission.student != user and submission.assignment.owner != user:
			return Response({"detail": "You are not allowed to view this submission."}, status=status.HTTP_403_FORBIDDEN)

		if not submission.file_blob:
			return Response({"detail": "No file available."}, status=status.HTTP_404_NOT_FOUND)

		content_type = submission.file_content_type or "application/octet-stream"
		resp = HttpResponse(submission.file_blob, content_type=content_type)
		filename = submission.file_name or f"submission-{submission.id}"
		resp["Content-Disposition"] = f'attachment; filename="{filename}"'
		return resp


class SubmissionDetailView(generics.RetrieveUpdateDestroyAPIView):
	queryset = Submission.objects.select_related('assignment', 'student').defer('file_blob').all()
	serializer_class = SubmissionSerializer
	authentication_classes = []
	permission_classes = [permissions.AllowAny]

	def get(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		submission = self.get_object()
		# teacher owner of the assignment or the student may view
		if submission.student != user and submission.assignment.owner != user:
			return Response({'detail': 'You are not allowed to view this submission.'}, status=status.HTTP_403_FORBIDDEN)
		return Response(self.serializer_class(submission, context={"request": request}).data, status=status.HTTP_200_OK)

	def put(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		submission = self.get_object()
		# allow teacher to update grade/feedback
		if submission.assignment.owner != user:
			return Response({'detail': 'Only the assignment owner can modify this submission.'}, status=status.HTTP_403_FORBIDDEN)
		return super().put(request, *args, **kwargs)

	def delete(self, request, *args, **kwargs):
		user = _get_current_user_from_token(request)
		submission = self.get_object()
		# student may delete their own submission, teacher may delete any
		if submission.student != user and submission.assignment.owner != user:
			return Response({'detail': 'You are not allowed to delete this submission.'}, status=status.HTTP_403_FORBIDDEN)
		return super().delete(request, *args, **kwargs)
