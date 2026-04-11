from django.db import models

# Create your models here.
class Subject(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    owner = models.ForeignKey('authentication.User', on_delete=models.CASCADE, related_name='subjects')
    enrolled_students = models.ManyToManyField('authentication.User', related_name='enrolled_subjects', blank=True)
    is_completed = models.BooleanField(default=False)

    def __str__(self):
        return self.name