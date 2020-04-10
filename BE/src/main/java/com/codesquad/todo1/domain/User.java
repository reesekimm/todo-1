package com.codesquad.todo1.domain;

import lombok.Getter;
import lombok.ToString;
import org.springframework.data.annotation.Id;

@Getter
@ToString
public class User {
    @Id
    private Long id;

    private String userId;
    private String password;
}
