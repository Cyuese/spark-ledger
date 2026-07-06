import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/calc_expression.dart';

void main() {
  group('evaluateAmountExpression', () {
    test('纯数字原样求值', () {
      expect(evaluateAmountExpression('500'), 500);
      expect(evaluateAmountExpression('12.5'), 12.5);
      expect(evaluateAmountExpression('0.99'), 0.99);
    });

    test('加减法', () {
      expect(evaluateAmountExpression('500+800'), 1300);
      expect(evaluateAmountExpression('1000-200'), 800);
      expect(evaluateAmountExpression('1+2+3'), 6);
    });

    test('乘除优先于加减', () {
      expect(evaluateAmountExpression('500×3'), 1500);
      expect(evaluateAmountExpression('100÷4'), 25);
      expect(evaluateAmountExpression('2+3×4'), 14);
      expect(evaluateAmountExpression('10-6÷2'), 7);
    });

    test('首位负号视为负数', () {
      expect(evaluateAmountExpression('-500'), -500);
      expect(evaluateAmountExpression('-500+200'), -300);
    });

    test('不完整算式返回 null', () {
      expect(evaluateAmountExpression('500+'), isNull);
      expect(evaluateAmountExpression('500×'), isNull);
      expect(evaluateAmountExpression('500+-'), isNull);
      expect(evaluateAmountExpression('+'), isNull);
      expect(evaluateAmountExpression(''), isNull);
    });

    test('除以零无效', () {
      expect(evaluateAmountExpression('5÷0'), isNull);
    });

    test('末尾小数点仍可解析', () {
      expect(evaluateAmountExpression('500.'), 500);
    });
  });

  group('amountExpressionHasOperator', () {
    test('纯数字（含首位负号）不算算式', () {
      expect(amountExpressionHasOperator('500'), isFalse);
      expect(amountExpressionHasOperator('-500'), isFalse);
      expect(amountExpressionHasOperator('12.5'), isFalse);
    });

    test('含运算符即为算式', () {
      expect(amountExpressionHasOperator('500+800'), isTrue);
      expect(amountExpressionHasOperator('500×3'), isTrue);
      expect(amountExpressionHasOperator('1000-200'), isTrue);
    });
  });
}
