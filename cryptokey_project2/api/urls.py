# api/urls.py

from django.urls import path
from .views import (
    ApiHomeView,
    PasswordEntryListCreateView, PasswordEntryDetailView,
    SecureNoteListCreateView, SecureNoteDetailView,
    CreditCardListCreateView, CreditCardDetailView,
    IdentityCardListCreateView, IdentityCardDetailView,
    EncryptionKeyListCreateView, EncryptionKeyDetailView,
    check_password, import_passwords, export_passwords, share_password,
    add_password, password_list, delete_password, update_password,
    secure_note_list, add_secure_note, update_secure_note, delete_secure_note,
    identity_card_list, add_identity_card, update_identity_card, delete_identity_card,
    credit_card_list, add_credit_card, update_credit_card, delete_credit_card,
    encryption_key_list, add_encryption_key, update_encryption_key, delete_encryption_key,
    UserListView, UserDetailView, MyTokenObtainPairView, UserDeleteView, UserUpdateView, NotifyPasswordLeakView, StatisticsView,GetUserPasswords,
    user_register, user_login, get_user_profile, update_profile,send_2fa_code,
)

urlpatterns = [
    path('', ApiHomeView.as_view(), name='api-home'),
    path('passwords/', PasswordEntryListCreateView.as_view(), name='password-list-create'),
    path('passwords/<int:pk>/', PasswordEntryDetailView.as_view(), name='password-detail'),
    path('notes/', SecureNoteListCreateView.as_view(), name='note-list-create'),
    path('notes/<int:pk>/', SecureNoteDetailView.as_view(), name='note-detail'),
    path('cards/', CreditCardListCreateView.as_view(), name='card-list-create'),
    path('cards/<int:pk>/', CreditCardDetailView.as_view(), name='card-detail'),
    path('identities/', IdentityCardListCreateView.as_view(), name='identity-list-create'),
    path('identities/<int:pk>/', IdentityCardDetailView.as_view(), name='identity-detail'),
    path('keys/', EncryptionKeyListCreateView.as_view(), name='key-list-create'),
    path('keys/<int:pk>/', EncryptionKeyDetailView.as_view(), name='key-detail'),
    path('check_password/', check_password, name='check_password'),
    path('users/', UserListView.as_view(), name='user-list'),
    path('users/<int:pk>/', UserDetailView.as_view(), name='user-detail'),
    path('token/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    
    path('profile/', get_user_profile, name='get_user_profile'),
    path('register/', user_register, name='register'),
    path('profile/update/<int:user_id>/', update_profile, name='update_profile'),
    path('login/', user_login, name='user-login'),

    # password
    path('password_list/', password_list, name='password_list'),
    path('passwords/add/', add_password, name='add_password'),
    path('passwords/update/<int:password_id>/', update_password, name='update_password'),
    path('passwords/delete/<int:password_id>/', delete_password, name='delete_password'),

    # Secure Note
    path('notes/', secure_note_list, name='secure_note_list'),
    path('notes/add/', add_secure_note, name='add_secure_note'),
    path('notes/update/<int:note_id>/', update_secure_note, name='update_secure_note'),
    path('notes/delete/<int:note_id>/', delete_secure_note, name='delete_secure_note'),

    # Identity Card
    path('identities/', identity_card_list, name='identity_card_list'),
    path('identities/add/', add_identity_card, name='add_identity_card'),
    path('identities/update/<int:card_id>/', update_identity_card, name='update_identity_card'),
    path('identities/delete/<int:card_id>/', delete_identity_card, name='delete_identity_card'),

    # Credit Card
    path('cards/', credit_card_list, name='credit_card_list'),
    path('cards/add/', add_credit_card, name='add_credit_card'),
    path('cards/update/<int:card_id>/', update_credit_card, name='update_credit_card'),
    path('cards/delete/<int:card_id>/', delete_credit_card, name='delete_credit_card'),

    # Encryption Key
    path('keys/', encryption_key_list, name='encryption_key_list'),
    path('keys/add/', add_encryption_key, name='add_encryption_key'),
    path('keys/update/<int:key_id>/', update_encryption_key, name='update_encryption_key'),
    path('keys/delete/<int:key_id>/', delete_encryption_key, name='delete_encryption_key'),

    # share
    path('share/', share_password, name='share_password'),

    path('export/', export_passwords, name='export_passwords'),

    path('import/', import_passwords, name='export_passwords'),

    # admin
    path('users/', UserListView.as_view(), name='user-list'),
    path('users/<int:pk>/', UserDetailView.as_view(), name='user-detail'),
    path('users/<int:pk>/delete/', UserDeleteView.as_view(), name='user-delete'),
    path('users/<int:pk>/update/', UserUpdateView.as_view(), name='user-update'),
    path('users/<int:user_id>/passwords/', GetUserPasswords.as_view(), name='get_user_passwords'),
    path('users/<int:pk>/notify_password_leak/', NotifyPasswordLeakView.as_view(), name='notify-password-leak'),

    # stats and logs
    path('statistics/', StatisticsView.as_view(), name='statistics'),
    


    path('send_2fa/', send_2fa_code, name='send_2fa_code'),

]
