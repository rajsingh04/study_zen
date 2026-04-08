from .models import Subject
from authentication.serializer import UserSerializer
from rest_framework import serializers

class SubjectSerializer(serializers.ModelSerializer):
    owner = UserSerializer(read_only=True)
    enrolled_students = UserSerializer(many=True, read_only=True)

    class Meta:
        model = Subject
        fields = '__all__'