package zcla71.doccat;

import java.io.IOException;

import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class App {
	public static void main(String[] args) throws IOException {
		// SpringApplication.run(DocCatApplication.class, args);
		App app = new App();
		app.download();
	}

	private void download() throws IOException {
	}
}
