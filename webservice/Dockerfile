FROM node:bullseye-slim
WORKDIR /usr/share/app
COPY package.json package.json
COPY package-lock.json package-lock.json
RUN npm install
RUN mkdir uploads
COPY . .
EXPOSE 5000
CMD [ "npm", "start" ]