class ShuntingYard
  class UnmatchedParensError < Exception;end

  class UnknownTokenError < Exception;end

  class InsufficientArgumentsError < Exception; end

  attr_reader :operator_precedences, :left_associated_operators, :op_arg_counts, :operators

  def initialize
    @operator_precedences = {'!' => 4, '^' => 4, '*' => 3, '/' => 3, '%' => 3, '+' => 2, '-' => 2, '=' => 1}
    @left_associated_operators = {'*' => true, '^' => false, '/' => true, '%' => true, '+' => true, '-' => true, '=' => false, '!' => false}
    @op_arg_counts = {'*' => 2, '^' => 2, '/' => 2, '%' => 2, '+' => 2, '-' => 2, '=' => 2, '!' => 1}
    @operators = {'*' => true, '/' => true, '%' => true, '+' => true, '-' => true, '=' => true, '!' => true, '^' => true}
  end

  def operator_precedence(op)
    operator_precedences[op] || 0
  end

  def op_left_association(op)
    left_associated_operators[op] || false
  end

  def op_arg_count(op)
    op_arg_counts[op] || (op.bytes.first - 'A'.bytes.first)
  end

  def is_operator(char)
    !!operators[char]
  end

  def is_function(char)
    char >= 'A' && char <= 'Z'
  end

  def is_ident(char)
    (char >= '0' && char <= '9') || (char >= 'a' && char <= 'z')
  end

  def shunting_yard(input)
    output = []
    stack = []
    input.each_char do |char|
      if char != ' '
        if(is_ident(char))
          # If the token is a number (identifier), then add it to the output queue
          output << char
        elsif(is_function(char))
          # If the token is a function token, then push it onto the stack
          stack.push(char)
        elsif(char == ',')
          # If the token is a function argument separator (e.g., a comma)
          paren_close = false

          until stack.empty?
            current_op = stack.last
            if current_op == '('
              paren_close = true
              break
            else
              # Until the top token on the stack is a left parenthesis,
              # pop operators off the stack onto the output queue
              output << stack.pop
            end
          end

          unless paren_close
            # There was an error, raise the error
            raise UnmatchedParensError.new("Function argument separator with unmatched parenthesis")
          end
        elsif is_operator(char)
          # If the token is an operator, then:
          until stack.empty?
            # While there is an operator token, op2, at the top of the stack
            # if op1 (our current operator) is left-associative and its precedence is
            # lower than or equal to that of op2, or op1 is right-associative and
            # its precedence is less than that of op2
            op2 = stack.last
            if (op_left_association(char) && operator_precedence(char) <= operator_precedence(op2)) || 
               (operator_precedence(char) < operator_precedence(op2))
              # Pop the operator off the stack and onto the output queue
              output << stack.pop
            else
              break
            end
          end

          # Push op1 onto the stack
          stack.push(char)
        elsif char == '('
          stack << char
        elsif char == ')'
          # Until the token at the top of the stack is a left parenthesis,
          # pop operators off the stack onto the output queue
          parens_open = false
          until stack.empty?
            current_op = stack.pop
            if current_op == '('
              parens_open = true
              break
            else
              output << current_op
            end
          end

          unless parens_open
            # No parens open found, raise the unmatched parens error
            raise UnmatchedParensError.new("Unmatched right parenthesis")
          end

          unless stack.empty?
            current_op = stack.last
            if is_function(current_op)
              output << stack.pop
            end
          end
        else
          # Unknown token, raise the error
          raise UnknownTokenError.new("Unknown token: #{char}")
        end
      end
    end

    # When there are no more tokens to read:
    until stack.empty?
      # While there are still operator tokens on the stack
      current_op = stack.pop
      if current_op == '(' || current_op == ')'
        # Unmatched parens, raise the error
        raise UnmatchedParensError.new("Leftover parens on the stack")
      end

      output << current_op
    end

    return output
  end

  def execution_order(input)
    puts "order:"
    stack = []
    rn = 0

    input.each do |current_token|
      if is_ident(current_token)
        stack.push(current_token)
      elsif is_operator(current_token) || is_function(current_token)
        response = sprintf("_%02d", rn)
        rn += 1
        print "#{response} = " 

        # How many operators does the operator take?
        n_args = op_arg_count(current_token)

        # If there are fewer than n_args values on the stack
        if stack.size < n_args
          raise InsufficientArgumentsError.new("Insufficient arguments on the stack to process #{current_token}")
        end

        # Pop the top n values from the stack, and evaluate the operator with the values as arguments
        if(is_function(current_token))
          print("#{current_token}(")
          local_args = []
          n_args.times do
            local_args.unshift(stack.pop)
          end

          puts "#{local_args.join(",")})"
        else
          if n_args == 1
            puts "#{current_token} #{stack.pop}"
          else
            op2,op1 = stack.pop,stack.pop
            puts "#{op1} #{current_token} #{op2}"
          end
        end

        stack.push(response)
      end
    end

    # If there is only one value in the stack that value is the result of the calculation
    if stack.size == 1
      puts stack.last
      puts "#{stack.pop()} is a result"
    end    
  end

  def ShuntingYard.parse(input)
    sy = ShuntingYard.new
    begin
      output = sy.shunting_yard(input)
      puts "#{input} => #{output}\n=>"
      puts sy.execution_order(output)
    rescue ShuntingYard::UnmatchedParensError => error
      puts "There was an error during parsing: #{error}"
    rescue ShuntingYard::UnknownTokenError => error
      puts "There was an error during parsing: #{error}"
    end
  end
end