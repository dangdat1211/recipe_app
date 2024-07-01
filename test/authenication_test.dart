// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:recipe_app/service/auth_service.dart';

// class MockFirebaseAuth extends Mock implements FirebaseAuth {}
// class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
// class MockUserCredential extends Mock implements UserCredential {}
// class MockUser extends Mock implements User {}

// void main() {
//   late AuthService authService;
//   late MockFirebaseAuth mockFirebaseAuth;
//   late MockFirebaseFirestore mockFirebaseFirestore;
//   late MockUserCredential mockUserCredential;
//   late MockUser mockUser;

//   setUp(() {
//     mockFirebaseAuth = MockFirebaseAuth();
//     mockFirebaseFirestore = MockFirebaseFirestore();
//     mockUserCredential = MockUserCredential();
//     mockUser = MockUser();
//     authService = AuthService(
//       auth: mockFirebaseAuth,
//       firestore: mockFirebaseFirestore
//     );
//   });

//   test('register creates new user and sends verification email', () async {
//     // Arrange
//     when(mockFirebaseAuth.createUserWithEmailAndPassword(
//       email: 'test@example.com',
//       password: 'password123',
//     )).thenAnswer((_) async => mockUserCredential);
//     when(mockUserCredential.user).thenReturn(mockUser);
//     when(mockUser.uid).thenReturn('testuid');
//     when(mockUser.sendEmailVerification()).thenAnswer((_) async => {});

//     // Act
//     await authService.register(
//       username: 'testuser',
//       fullname: 'Test User',
//       email: 'test@example.com',
//       password: 'password123',
//     );

//     // Assert
//     verify(mockFirebaseAuth.createUserWithEmailAndPassword(
//       email: 'test@example.com',
//       password: 'password123',
//     )).called(1);
//     verify(mockUser.sendEmailVerification()).called(1);
    
//   });

//   // Thêm các test case khác ở đây
// }