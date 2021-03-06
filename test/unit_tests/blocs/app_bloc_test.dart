import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http show Client, Response;
import 'package:mockito/mockito.dart' show Mock, when;

import 'package:nhie/blocs/app/app.dart';
import 'package:nhie/blocs/statement/statement.dart';
import 'package:nhie/env.dart';
import 'package:nhie/models/category_name.dart';
import 'package:nhie/models/category.dart';
import 'package:nhie/models/statement.dart';
import 'package:nhie/services/statement_api_provider.dart';

import '../../setup.dart';

class MockClient extends Mock implements http.Client {}

class MockStatementBloc extends MockBloc<StatementState>
    implements StatementBloc {}

Statement next(Iterator<Statement> iterator) {
  iterator.moveNext();
  return iterator.current;
}

main() async {
  await defaultSetup();

  MockClient client = MockClient();
  StatementApiProvider.client = client;
  final uuid = StatementApiProvider.uuid;

  List<Category> categories = [
    Category(
        name: CategoryName.harmless,
        selectedImageUri: 'assets/categories/mojito.svg',
        unselectedImageUri: 'assets/categories/mojito_gray.svg',
        selected: true),
    Category(
        name: CategoryName.delicate,
        selectedImageUri: 'assets/categories/beer.svg',
        unselectedImageUri: 'assets/categories/beer_gray.svg',
        selected: false),
    Category(
        name: CategoryName.offensive,
        selectedImageUri: 'assets/categories/cocktail.svg',
        unselectedImageUri: 'assets/categories/cocktail_gray.svg',
        selected: false),
  ];

  Iterable<Statement> statementIterable = Iterable.castFrom([
    Statement(
      uuid: 'e1ce4647-c87d-4a0f-a91b-8db204e8889d',
      text: 'Never have I ever told somebody that I love his/her body.',
      category: CategoryName.harmless,
    ),
    Statement(
      uuid: 'ec2a37e7-da79-44dc-b292-a5c343c0eaa8',
      text: 'Never have I ever forgotten to buy a present.',
      category: CategoryName.harmless,
    ),
  ]);
  Statement statement = Statement(
    uuid: 'e1ce4647-c87d-4a0f-a91b-8db204e8889d',
    text: 'Never have I ever told somebody that I love his/her body.',
    category: CategoryName.harmless,
  );

  Exception exception = SocketException('Bad status code');

  group('bloc fetch statement', () {
    AppBloc appBloc;

    setUp(() {
      appBloc = AppBloc(statementBloc: StatementBloc());
      Iterator<Statement> expectedResponse = statementIterable.iterator;
      when(client.get(
              '${env.baseUrl}/statements/random?category[]=harmless&game_id=$uuid&language='))
          .thenAnswer((_) async {
        var current = jsonEncode(next(expectedResponse));
        return http.Response(current, 200);
      });
    });

    tearDown(() {
      appBloc?.close();
    });

    test('initial state is empty', () async {
      expect(appBloc.statements, []);
      expect(appBloc.currentStatementIndex, -1);
      expect(appBloc.categories, null);
    });

    test('initial state is uninitialized', () {
      expect(appBloc.state, Uninitialized());
    });

    blocTest('emits [Initialized(),] when initialized',
        build: () => appBloc,
        act: (AppBloc bloc) async => bloc.add(Initialize(categories)),
        expect: <AppState>[
          Initialized(),
        ]);

    blocTest('emits [Initialized(),] when initialized', build: () {
      when(client.get(
              '${env.baseUrl}/statements/random?category[]=harmless&game_id=$uuid&language='))
          .thenAnswer((_) async {
        return http.Response('', 400);
      });
      return appBloc;
    }, act: (AppBloc bloc) async {
      bloc.add(Initialize(categories));
      Timer(Duration(seconds: 1), () {});
    }, expect: <AppState>[
      Initialized(),
      AppException(exception),
    ]);

    blocTest('emits [Initialized(),] when initialized',
        build: () {
          when(client.get(
                  '${env.baseUrl}/statements/random?category[]=harmless&game_id=$uuid&language='))
              .thenAnswer((_) async {
            return http.Response(jsonEncode(statement), 200);
          });
          return appBloc;
        },
        act: (AppBloc bloc) async =>
            bloc..add(Initialize(categories))..add(GoForward(categories: categories)),
        expect: <AppState>[
          Initialized(),
          Forward(statement),
        ]);
  });
}
