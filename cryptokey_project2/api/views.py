# api/views.py

from datetime import datetime
from django.contrib.auth.decorators import login_required
import logging
from django.http import HttpResponse, JsonResponse
from django.db import IntegrityError
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, get_user_model
from django.contrib.auth.models import User
from django.views import View
from rest_framework.views import APIView
from rest_framework.response import Response
from django.contrib.auth.hashers import make_password
from django.core.mail import send_mail
from django.contrib.auth.password_validation import validate_password
from rest_framework import status
from rest_framework import generics
from django.db.models import Count
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import csrf_exempt
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from datetime import timedelta
from django_ratelimit.decorators import ratelimit
from django.contrib.auth.hashers import make_password, check_password
from django.views.decorators.http import require_http_methods
from django.conf import settings
import csv
import json
from .models import PasswordEntry, SecureNote, CreditCard, IdentityCard, EncryptionKey, PasswordEntry, PasswordShare, Log, decrypt_data, encrypt_data
from .serializers import (
    PasswordEntrySerializer, SecureNoteSerializer,
    CardSerializer, IdentitySerializer,
    EncryptionKeySerializer, UserSerializer,
    PasswordShareSerializer, PasswordImportSerializer,PasswordExportSerializer, LogSerializer, TwoFactorSerializer
)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

User = get_user_model()



################### obtention de token d'authetification ##########################

class MyTokenObtainPairView(TokenObtainPairView):
    permission_classes = [AllowAny]



################### view generique user ##########################

class UserListView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    def get(self, request, *args, **kwargs):
        token = request.headers.get('Authorization')
        print(f'Token: {token}')  # Log the token for debugging purposes
        return super().get(request, *args, **kwargs)
    def get_queryset(self):
        return User.objects.exclude(username='admin')

class UserDetailView(generics.RetrieveAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]



class ApiHomeView(View):
    def get(self, request):
        return HttpResponse("Welcome to the Cryptokey API home page!")



################### view generique paswword ##########################

class PasswordEntryListCreateView(generics.ListCreateAPIView):
    serializer_class = PasswordEntrySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return PasswordEntry.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class PasswordEntryDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = PasswordEntrySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return PasswordEntry.objects.filter(user=self.request.user)


################### view generique secure note ##########################

class SecureNoteListCreateView(generics.ListCreateAPIView):
    queryset = SecureNote.objects.all()
    serializer_class = SecureNoteSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class SecureNoteDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = SecureNote.objects.all()
    serializer_class = SecureNoteSerializer
    permission_classes = [IsAuthenticated]


################### view generique credit card ##########################

class CreditCardListCreateView(generics.ListCreateAPIView):
    queryset = CreditCard.objects.all()
    serializer_class = CardSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class CreditCardDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = CreditCard.objects.all()
    serializer_class = CardSerializer
    permission_classes = [IsAuthenticated]

################### view generique id card ##########################


class IdentityCardListCreateView(generics.ListCreateAPIView):
    queryset = IdentityCard.objects.all()
    serializer_class = IdentitySerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class IdentityCardDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = IdentityCard.objects.all()
    serializer_class = IdentitySerializer
    permission_classes = [IsAuthenticated]

################### view generique encryption key ##########################

class EncryptionKeyListCreateView(generics.ListCreateAPIView):
    queryset = EncryptionKey.objects.all()
    serializer_class = EncryptionKeySerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class EncryptionKeyDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = EncryptionKey.objects.all()
    serializer_class = EncryptionKeySerializer
    permission_classes = [IsAuthenticated]


################### verifie la force d'un mdp ##########################


def check_password_strength(password):
    length = len(password)
    has_digit = any(char.isdigit() for char in password)
    has_special_char = any(char in "!@#$%^&*()-_+=~`[]{}|;:'\",.<>?/" for char in password)

    strength = 0

    if length >= 8:
        strength += 20
    if has_digit:
        strength += 20
    if has_special_char:
        strength += 20

    return strength


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def check_password(request):
    password = request.data.get('password')
    strength = check_password_strength(password)
    return JsonResponse({"strength": strength})



################### admin delete ##########################
class UserDeleteView(generics.DestroyAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
################### admin edit ##########################
class UserUpdateView(generics.UpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        data = request.data

        # Handle password update separately
        password = data.pop('password', None)

        serializer = self.get_serializer(instance, data=data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        if password:
            instance.set_password(password)
            instance.save()

        return Response(serializer.data)
################### admin password leak ##########################
logger = logging.getLogger(__name__)

class NotifyPasswordLeakView(APIView):
    def post(self, request, pk):
        try:
            logger.debug(f"Notifying user with ID: {pk}")
            user = User.objects.get(pk=pk)
            site_name = request.data.get('site_name')  # Récupère le nom du site depuis la requête
            if not site_name:
                logger.error("site_name is missing in the request.")
                return Response({'error': 'site_name is required'}, status=status.HTTP_400_BAD_REQUEST)

            # Envoyer un e-mail à l'utilisateur
            subject = "Mot de passe compromis pour votre compte"
            message = f"Bonjour {user.username},\n\nVotre mot de passe pour le site '{site_name}' a été signalé comme compromis. Nous vous recommandons de le changer immédiatement."
            email_from = settings.DEFAULT_FROM_EMAIL
            recipient_list = [user.email]
            send_mail(subject, message, email_from, recipient_list)

            return Response({'message': 'User notified successfully.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            logger.error("User not found.")
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            logger.error(f"Unexpected error: {e}", exc_info=True)
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        

def notify_user_by_email(user, site_name):
    subject = "Mot de passe compromis pour votre compte"
    message = f"Bonjour {user.username},\n\nVotre mot de passe pour le site '{site_name}' a été signalé comme compromis. Nous vous recommandons de le changer immédiatement."
    email_from = settings.DEFAULT_FROM_EMAIL
    recipient_list = [user.email]
    send_mail(subject, message, email_from, recipient_list)
    
################### admin stat ##########################
class StatisticsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        logger = logging.getLogger(__name__)
        try:
            total_users = User.objects.count()
            latest_user = User.objects.latest('date_joined')
            latest_user_joined = latest_user.date_joined
            user_activity = User.objects.filter(last_login__gte=timezone.now() - timedelta(days=30)).count()

            users = User.objects.all()
            user_data = []
            for user in users:
                user_data.append({
                    'username': user.username,
                    'date_joined': user.date_joined,
                    'last_login': user.last_login,
                })

            data = {
                'total_users': total_users,
                'latest_user_joined': latest_user_joined,
                'user_activity': user_activity,
                'users': user_data
            }
            logger.info(f"Statistics data prepared: {data}")
            return Response(data)
        except Exception as e:
            logger.error(f"Error in StatisticsView: {e}")
            return Response({'error': 'Internal Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



################### partage de mots de passe ##########################

logger = logging.getLogger(__name__)

@api_view(['POST', 'GET'])
@permission_classes([IsAuthenticated])
def share_password(request):
    if request.method == 'POST':
        try:
            # Récupération des données du POST
            shared_with_user_id = request.data.get('shared_with_user_id')
            shared_by_user_id = request.user.id  # Utilisez l'utilisateur connecté
            password_entry_id = request.data.get('password_entry_id')
            expiration_date = request.data.get('expiration_date')

            logger.debug(f"expiration_date (before conversion): {expiration_date}")

            # Convertir l'expiration_date en datetime aware
            if expiration_date:
                expiration_date = timezone.make_aware(
                    datetime.strptime(expiration_date, "%Y-%m-%dT%H:%M:%S.%f")
                )
            logger.debug(f"expiration_date (after conversion): {expiration_date}")

            # Vérifier si l'utilisateur avec lequel partager existe
            shared_with_user = User.objects.get(id=shared_with_user_id)

            # Vérifier si l'entrée de mot de passe existe
            password_entry = PasswordEntry.objects.get(id=password_entry_id)

            # Vérifier si cette combinaison existe déjà
            if PasswordShare.objects.filter(password_entry=password_entry, shared_with_user=shared_with_user, shared_by_user=request.user).exists():
                return Response({'error': 'This password has already been shared with this user.'}, status=status.HTTP_400_BAD_REQUEST)

            # Créer et sauvegarder l'objet PasswordShare
            password_share = PasswordShare.objects.create(
                password_entry=password_entry,
                shared_with_user=shared_with_user,
                shared_by_user=request.user,
                expiration_date=expiration_date
            )
            logger.debug(f"password_share created: {password_share}")

            # Sérialiser l'instance de PasswordShare
            serializer = PasswordShareSerializer(password_share)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        except User.DoesNotExist:
            logger.error("Shared with user not found")
            return Response({'error': 'Shared with user not found'}, status=status.HTTP_404_NOT_FOUND)
        
        except PasswordEntry.DoesNotExist:
            logger.error("Password entry not found")
            return Response({'error': 'Password entry not found'}, status=status.HTTP_404_NOT_FOUND)

        except IntegrityError as e:
            logger.error(f"Integrity error occurred: {e}")
            return Response({'error': 'An integrity error occurred, possibly due to a duplicate entry.'}, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            logger.error(f"Exception occurred: {e}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    elif request.method == 'GET':
        try:
            # Filtrer les mots de passe partagés avec l'utilisateur connecté, non expirés
            shared_passwords = PasswordShare.objects.filter(shared_with_user=request.user)

            # Sérialiser les mots de passe partagés
            serializer = PasswordShareSerializer(shared_passwords, many=True)

            # Retourner les données sérialisées
            return Response(serializer.data, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Exception occurred: {e}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    else:
        return Response({'message': 'Method not allowed'}, status=status.HTTP_405_METHOD_NOT_ALLOWED)

################### import de mdp ##########################


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def import_passwords(request):
    if request.method == 'POST':
        try:
            format = request.data.get('format')
            if format not in ['json', 'csv']:
                return JsonResponse({"error": "Invalid import format specified"}, status=400)

            if format == 'json':
                imported_data = json.loads(request.data.get('data'))
                serializer = PasswordImportSerializer(data=imported_data, many=True)
            elif format == 'csv':
                csv_data = request.FILES['file'].read().decode('utf-8').splitlines()
                csv_reader = csv.DictReader(csv_data)
                imported_data = list(csv_reader)
                serializer = PasswordImportSerializer(data=imported_data, many=True)
            
            if serializer.is_valid():
                serializer.save(user=request.user)
                return JsonResponse({"status": "Passwords imported successfully"}, status=200)
            else:
                return JsonResponse({"error": serializer.errors}, status=400)
        except Exception as e:
            # Log the exception for debugging
            import traceback
            traceback.print_exc()
            return JsonResponse({'error': str(e)}, status=500)
    else:
        return JsonResponse({'message': 'Method not allowed'}, status=405)




################### export de mdp ##########################

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def export_passwords(request):
    try:
        # Récupérer tous les mots de passe de l'utilisateur actuel
        passwords = PasswordEntry.objects.filter(user=request.user)

        # Vérifier le format demandé (JSON ou CSV)
        export_format = request.data.get('format', 'json')

        if export_format == 'json':
            # Sérialiser les mots de passe en JSON
            passwords_data = [{'id': p.id, 'user': p.user.id, 'site_name': p.site_name, 'site_url': p.site_url,
                               'username': p.username, 'password': p.password, 'created_at': p.created_at,
                               'updated_at': p.updated_at} for p in passwords]
            return JsonResponse(passwords_data, safe=False)

        elif export_format == 'csv':
            # Créer un fichier CSV temporaire
            response = HttpResponse(content_type='text/csv')
            response['Content-Disposition'] = 'attachment; filename="passwords.csv"'
            writer = csv.writer(response)
            writer.writerow(['id', 'user', 'site_name', 'site_url', 'username', 'password', 'created_at', 'updated_at'])
            for password in passwords:
                writer.writerow([password.id, password.user.id, password.site_name, password.site_url,
                                 password.username, password.password, password.created_at, password.updated_at])
            return response

        else:
            return JsonResponse({'error': 'Invalid format specified'}, status=400)
    
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)



################### USERS ##########################


# Utiliser le modèle utilisateur configuré dans le projet

logger = logging.getLogger(__name__)

@api_view(['POST'])
@ratelimit(key='ip', rate='5/m', method='POST', block=True)
def user_login(request):
    logger = logging.getLogger(__name__)
    logger.info("user_login called")

    if request.method == 'POST':
        username = request.data.get('username')
        password = request.data.get('password')
        logger.info(f"Username: {username}, Password: {'*' * len(password)}")

        if not username or not password:
            logger.warning("Username and password are required")
            return Response({'error': 'Username and password are required.'}, status=400)

        user = authenticate(request, username=username, password=password)
        
        if user is not None:
            login(request, user)  # Met à jour automatiquement last_login
            logger.info(f"User {username} authenticated successfully")

            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'last_login': user.last_login,
                }
            }, status=200)
        else:
            logger.warning(f"Invalid username or password for user {username}")
            return Response({'error': 'Invalid username or password'}, status=400)


@api_view(['POST'])
@permission_classes([AllowAny])
def send_2fa_code(request):
    serializer = TwoFactorSerializer(data=request.data)
    
    if serializer.is_valid():
        username = serializer.validated_data['username']
        code = serializer.validated_data['code']
        
        try:
            user = User.objects.get(username=username)
            email = user.email
            
            send_mail(
                'Votre code de vérification 2FA',
                f'Votre code de vérification est : {code}',
                'admin@lebourbier.be',  # Utilisez une adresse e-mail valide de votre domaine
                [email],
                fail_silently=False,
            )
            return Response({'message': '2FA code sent successfully'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def user_register(request):
    # Sérialisation des données de la requête
    serializer = UserSerializer(data=request.data)
    
    if serializer.is_valid():
        # Extraction des informations de l'utilisateur à partir des données sérialisées
        username = serializer.validated_data.get('username')
        email = serializer.validated_data.get('email')
        first_name = serializer.validated_data.get('first_name')
        last_name = serializer.validated_data.get('last_name')
        password = request.data.get('password')  # Le mot de passe est toujours requis pour la création

        # Vérification si le champ du mot de passe est vide
        if not password:
            logger.warning("Password is required")
            return Response({'message': 'Le mot de passe est requis'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Vérification de l'unicité du nom d'utilisateur
        if User.objects.filter(username=username).exists():
            logger.warning(f"Username '{username}' already exists")
            return Response({'message': 'Le nom d\'utilisateur existe déjà'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            validate_password(password)
        except Exception as e:
            logger.warning(f"Password validation error: {e}")
            return Response({'message': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        
        user = User.objects.create_user(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            password=password
        )
        
        if user:
            logger.info(f"User '{username}' registered successfully")
            return Response({'message': 'Inscription réussie', 'user': UserSerializer(user).data}, status=status.HTTP_201_CREATED)
        else:
            logger.error("User registration failed")
            return Response({'message': 'Échec de l\'inscription'}, status=status.HTTP_400_BAD_REQUEST)
    else:
        logger.warning(f"User registration validation errors: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

@api_view(['PATCH']) 
@permission_classes([IsAuthenticated])
def update_profile(request, user_id):
    if request.method == 'PATCH':
        try:
            user_profile = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'message': 'User profile does not exist'}, status=status.HTTP_404_NOT_FOUND)

        # Update profile fields
        user_profile.username = request.data.get('username', user_profile.username)
        user_profile.email = request.data.get('email', user_profile.email)
        user_profile.first_name = request.data.get('first_name', user_profile.first_name)
        user_profile.last_name = request.data.get('last_name', user_profile.last_name)

        # Check if new password is provided
        new_password = request.data.get('password')
        if new_password:
            # Set new password
            user_profile.set_password(new_password)

        # Save user profile
        user_profile.save()

        return Response({'message': 'Profile updated successfully', 'user': UserSerializer(user_profile).data}, status=status.HTTP_200_OK)
    
    return Response({'message': 'Method not allowed'}, status=status.HTTP_405_METHOD_NOT_ALLOWED)




@api_view(['GET']) # récuppération des donnée pour la page profil
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    user = request.user
    serializer = UserSerializer(user)
    return Response(serializer.data)

logger = logging.getLogger(__name__)

class GetUserPasswords(APIView):
    def get(self, request, user_id):
        try:
            logger.debug(f"Fetching user with ID: {user_id}")
            user = User.objects.get(pk=user_id)
            logger.debug("User found, fetching passwords...")
            
            # Assurez-vous que l'attribut 'passwordentry_set' existe
            passwords = [
                {'site_name': p.site_name, 'password': p.get_decrypted_password()} 
                for p in user.passwordentry_set.all()
            ]
            
            logger.debug("Passwords fetched and decrypted successfully.")
            return Response({'passwords': passwords})
        
        except User.DoesNotExist:
            logger.error("User not found.")
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        
        except Exception as e:
            logger.error(f"Unexpected error: {e}", exc_info=True)
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    





###################  PASSWORD ##########################

@csrf_exempt
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_password(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            site_name = data.get('site_name')
            site_url = data.get('site_url')
            username = data.get('username')
            password = data.get('password')

            # Logging the received data for debugging
            print(f"Received data: {data}")

            if not site_name or not site_url or not username or not password:
                return JsonResponse({'message': 'All fields are required'}, status=400)

            password_entry = PasswordEntry.objects.create(
                user=request.user,
                site_name=site_name,
                site_url=site_url,
                username=username,
                password=password
            )
            password_entry.save()

            serializer = PasswordEntrySerializer(password_entry)
            return JsonResponse(serializer.data, status=201)
        except Exception as e:
            print(f"Exception: {e}")
            return JsonResponse({'message': 'Bad request', 'error': str(e)}, status=400)
    else:
        return JsonResponse({'message': 'Method not allowed'}, status=405)
    

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_passwords(request):
    user = request.user
    passwords = PasswordEntry.objects.filter(user=user)
    for password in passwords:
        password.site = password.site or 'Unknown site'
        password.username = password.username or 'Unknown username'
        password.password = password.password or 'No password'
    serializer = PasswordEntrySerializer(passwords, many=True)
    return JsonResponse(serializer.data, status=200, safe=False)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_password(request, password_id):  # Ajout de password_id comme paramètre
    if request.method == 'PATCH':
        try:
            password_entry = PasswordEntry.objects.get(id=password_id, user=request.user)
        except PasswordEntry.DoesNotExist:
            return JsonResponse({'message': 'Password entry does not exist'}, status=404)

        password_entry.site_name = request.data.get('site_name', password_entry.site_name)
        password_entry.site_url = request.data.get('site_url', password_entry.site_url)
        password_entry.username = request.data.get('username', password_entry.username)
        password_entry.password = request.data.get('password', password_entry.password)
        password_entry.save()

        serializer = PasswordEntrySerializer(password_entry)
        return JsonResponse(serializer.data, status=200)
    
    return JsonResponse({'message': 'Method not allowed'}, status=405)

@login_required
def password_list(request):
    passwords = PasswordEntry.objects.filter(user=request.user)
    return render(request, 'password_list.html', {'passwords': passwords})

@csrf_exempt
@api_view(['DELETE'])
@login_required
def delete_password(request, password_id):
    try:
        password = PasswordEntry.objects.get(id=password_id, user=request.user)
        if password:
            password.delete()
            return JsonResponse({'message': 'Password deleted successfully'}, status=204)
        else:
            return JsonResponse({'error': 'Password not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
    

################### SECURE NOTE ##########################


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def add_secure_note(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            title = data.get('title')
            content = data.get('content')

            if not title or not content:
                return JsonResponse({'message': 'All fields are required'}, status=400)

            # Chiffrer le contenu avant de le sauvegarder
            encrypted_content = encrypt_data(content)

            secure_note = SecureNote.objects.create(
                user=request.user,
                title=title,
                encrypted_content=encrypted_content
            )
            secure_note.save()

            serializer = SecureNoteSerializer(secure_note)
            return JsonResponse(serializer.data, status=201)
        except Exception as e:
            return JsonResponse({'message': 'Bad request', 'error': str(e)}, status=400)
    else:
        return JsonResponse({'message': 'Method not allowed'}, status=405)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_secure_note(request, note_id):
    if request.method == 'PATCH':
        try:
            secure_note = SecureNote.objects.get(id=note_id, user=request.user)
        except SecureNote.DoesNotExist:
            return JsonResponse({'message': 'Secure note does not exist'}, status=404)

        title = request.data.get('title', secure_note.title)
        content = request.data.get('content', None)

        if content:
            secure_note.encrypted_content = encrypt_data(content)  # Chiffrer le nouveau contenu

        secure_note.title = title
        secure_note.save()

        serializer = SecureNoteSerializer(secure_note)
        return JsonResponse(serializer.data, status=200)

    return JsonResponse({'message': 'Method not allowed'}, status=405)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def secure_note_list(request):
    if request.method == 'GET':
        try:
            secure_notes = SecureNote.objects.filter(user=request.user)
            notes_data = []

            for note in secure_notes:
                try:
                    if note.encrypted_content:  # Assurez-vous que les données existent
                        decrypted_content = decrypt_data(note.encrypted_content)
                    else:
                        decrypted_content = "No content to decrypt"
                except Exception as e:
                    decrypted_content = "Error decrypting content"

                notes_data.append({
                    'id': note.id,
                    'title': note.title,
                    'content': decrypted_content  # Retourner le contenu déchiffré ou une erreur
                })

            return JsonResponse(notes_data, safe=False)
        except Exception as e:
            return JsonResponse({'message': 'Error retrieving notes', 'error': str(e)}, status=500)
    return JsonResponse({'message': 'Method not allowed'}, status=405)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_secure_note(request, note_id):
    try:
        secure_note = SecureNote.objects.get(id=note_id, user=request.user)
        if secure_note:
            secure_note.delete()
            return JsonResponse({'message': 'Secure note deleted successfully'}, status=204)
        else:
            return JsonResponse({'error': 'Secure note not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)




################### CREDIT CARD ##########################


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_credit_card(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            card_number = data.get('card_number')
            expiry_date = data.get('expiry_date')
            cvv = data.get('cvv')
            cardholder_name = data.get('cardholder_name')

            if not card_number or not expiry_date or not cvv or not cardholder_name:
                return JsonResponse({'message': 'All fields are required'}, status=400)

            # Chiffrer le numéro de carte avant de l'enregistrer
            encrypted_card_number = encrypt_data(card_number)

            credit_card = CreditCard.objects.create(
                user=request.user,
                encrypted_card_number=encrypted_card_number,
                expiry_date=expiry_date,
                cvv=cvv,
                cardholder_name=cardholder_name
            )
            credit_card.save()

            serializer = CardSerializer(credit_card)
            return JsonResponse(serializer.data, status=201)
        except Exception as e:
            return JsonResponse({'message': 'Bad request', 'error': str(e)}, status=400)
    else:
        return JsonResponse({'message': 'Method not allowed'}, status=405)

@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_credit_card(request, card_id):
    try:
        credit_card = CreditCard.objects.get(id=card_id, user=request.user)
    except CreditCard.DoesNotExist:
        return JsonResponse({'message': 'Credit card does not exist'}, status=404)

    card_number = request.data.get('card_number', None)
    if card_number:
        credit_card.encrypted_card_number = encrypt_data(card_number)

    credit_card.expiry_date = request.data.get('expiry_date', credit_card.expiry_date)
    credit_card.cvv = request.data.get('cvv', credit_card.cvv)
    credit_card.cardholder_name = request.data.get('cardholder_name', credit_card.cardholder_name)
    credit_card.save()

    serializer = CardSerializer(credit_card)
    return JsonResponse(serializer.data, status=200)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_credit_card(request, card_id):
    try:
        credit_card = CreditCard.objects.get(id=card_id, user=request.user)
        if credit_card:
            credit_card.delete()
            return JsonResponse({'message': 'Credit card deleted successfully'}, status=204)
        else:
            return JsonResponse({'error': 'Credit card not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@login_required
def credit_card_list(request):
    credit_cards = CreditCard.objects.filter(user=request.user)
    return render(request, 'credit_card_list.html', {'credit_cards': credit_cards})



################### IDENTITY CARD ##########################

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_identity_card(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            id_number = data.get('id_number')
            expiry_date = data.get('expiry_date')
            name = data.get('name')
            surname = data.get('surname')
            nationality = data.get('nationality')
            date_of_issue = data.get('date_of_issue')
            date_of_birth = data.get('date_of_birth')

            if not id_number or not expiry_date or not name or not surname or not nationality or not date_of_issue or not date_of_birth:
                return JsonResponse({'message': 'All fields are required'}, status=400)

            # Chiffrer le numéro d'identité avant de l'enregistrer
            encrypted_id_number = encrypt_data(id_number)

            identity_card = IdentityCard.objects.create(
                user=request.user,
                encrypted_id_number=encrypted_id_number,
                expiry_date=expiry_date,
                name=name,
                surname=surname,
                nationality=nationality,
                date_of_issue=date_of_issue,
                date_of_birth=date_of_birth
            )
            identity_card.save()

            serializer = IdentitySerializer(identity_card)
            return JsonResponse(serializer.data, status=201)
        except Exception as e:
            return JsonResponse({'message': 'Bad request', 'error': str(e)}, status=400)
    else:
        return JsonResponse({'message': 'Method not allowed'}, status=405)

@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_identity_card(request, card_id):
    try:
        identity_card = IdentityCard.objects.get(id=card_id, user=request.user)
    except IdentityCard.DoesNotExist:
        return JsonResponse({'message': 'Identity card does not exist'}, status=404)

    id_number = request.data.get('id_number', None)
    if id_number:
        identity_card.encrypted_id_number = encrypt_data(id_number)

    identity_card.expiry_date = request.data.get('expiry_date', identity_card.expiry_date)
    identity_card.name = request.data.get('name', identity_card.name)
    identity_card.surname = request.data.get('surname', identity_card.surname)
    identity_card.nationality = request.data.get('nationality', identity_card.nationality)
    identity_card.date_of_issue = request.data.get('date_of_issue', identity_card.date_of_issue)
    identity_card.date_of_birth = request.data.get('date_of_birth', identity_card.date_of_birth)
    identity_card.save()

    serializer = IdentitySerializer(identity_card)
    return JsonResponse(serializer.data, status=200)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_identity_card(request, card_id):
    try:
        identity_card = IdentityCard.objects.get(id=card_id, user=request.user)
        if identity_card:
            identity_card.delete()
            return JsonResponse({'message': 'Identity card deleted successfully'}, status=204)
        else:
            return JsonResponse({'error': 'Identity card not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@login_required
def identity_card_list(request):
    identity_cards = IdentityCard.objects.filter(user=request.user)
    return render(request, 'identity_card_list.html', {'identity_cards': identity_cards})

################### ENCRYPTION KEY ##########################

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_encryption_key(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            titles = data.get('titles')
            key = data.get('key')

            if not key or not titles:
                return JsonResponse({'message': 'All fields are required'}, status=400)

            # Chiffrer la clé avant de l'enregistrer
            encrypted_key = encrypt_data(key)

            encryption_key = EncryptionKey.objects.create(
                user=request.user,
                titles=titles,
                encrypted_key=encrypted_key
            )
            encryption_key.save()

            serializer = EncryptionKeySerializer(encryption_key)
            return JsonResponse(serializer.data, status=201)
        except Exception as e:
            return JsonResponse({'message': 'Bad request', 'error': str(e)}, status=400)
    else:
        return JsonResponse({'message': 'Method not allowed'}, status=405)

@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_encryption_key(request, key_id):
    try:
        encryption_key = EncryptionKey.objects.get(id=key_id, user=request.user)
    except EncryptionKey.DoesNotExist:
        return JsonResponse({'message': 'Encryption key does not exist'}, status=404)

    encryption_key.titles = request.data.get('titles', encryption_key.titles)
    key = request.data.get('key', None)
    if key:
        encryption_key.encrypted_key = encrypt_data(key)
    encryption_key.save()

    serializer = EncryptionKeySerializer(encryption_key)
    return JsonResponse(serializer.data, status=200)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_encryption_key(request, key_id):
    try:
        encryption_key = EncryptionKey.objects.get(id=key_id, user=request.user)
        encryption_key.delete()
        return JsonResponse({'message': 'Encryption key deleted successfully'}, status=204)
    except EncryptionKey.DoesNotExist:
        return JsonResponse({'error': 'Encryption key not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@login_required
def encryption_key_list(request):
    encryption_keys = EncryptionKey.objects.filter(user=request.user)
    return render(request, 'encryption_key_list.html', {'encryption_keys': encryption_keys})
