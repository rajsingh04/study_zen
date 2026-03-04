from django.db import models

# Create your models here.
class User(models.Model):
    STATUS_CHOICES = [
        ('STUDENT', 'Student'),
        ('TEACHER', 'Teacher'),
    ]
    username = models.CharField(max_length=150, unique=True)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=128)
    account_type=models.CharField(max_length=10,choices=STATUS_CHOICES,default='STUDENT')

    def __str__(self):
        return self.username
