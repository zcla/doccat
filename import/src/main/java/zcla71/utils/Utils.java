package zcla71.utils;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Properties;

import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;

import com.fasterxml.jackson.core.exc.StreamReadException;

public class Utils {
    public static Properties getPropertiesResourceAsObject(String resourceLocation) throws IOException {
        Resource resource = new ClassPathResource(resourceLocation);
        BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream()));
        Properties prop = new Properties();
        prop.load(reader);
        return prop;
    }

    public static <T> T getJsonResourceAsObject(Class<T> classe, String resourceLocation) throws StreamReadException, DatabindException, IOException {
        return getJsonResourceAsObject(classe, resourceLocation, null);
    }

    public static <T> T getJsonResourceAsObject(Class<T> classe, String resourceLocation, DeserializationFeature[] deserializationFeaturesToEnable) throws StreamReadException, DatabindException, IOException {
        Resource resource = new ClassPathResource(resourceLocation);
        BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream()));
        ObjectMapper objectMapper = new ObjectMapper();
        if (deserializationFeaturesToEnable != null) {
            for (DeserializationFeature deserializationFeature : deserializationFeaturesToEnable) {
                objectMapper.enable(deserializationFeature);
            }
        }
        return classe.cast(objectMapper.readValue(reader, classe));
    }
}
