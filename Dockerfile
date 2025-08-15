# Use Ruby 3.1.4 com bundler atualizado
FROM ruby:3.1.4

# Instale dependências do sistema
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    yarn \
    && rm -rf /var/lib/apt/lists/*

# Atualize RubyGems e Bundler
RUN gem update --system
RUN gem install bundler -v 2.4.22

# Configure o diretório de trabalho
WORKDIR /app

# Copie os arquivos Gemfile
COPY Gemfile* ./

# Configure bundler e instale gems
RUN bundle config --global frozen 0
RUN bundle install

# Copie o código da aplicação
COPY . .

# Exponha a porta 3000
EXPOSE 3000

# Comando padrão
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]